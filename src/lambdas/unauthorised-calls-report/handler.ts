import {
  AthenaClient,
  GetQueryExecutionCommand,
  GetQueryResultsCommand,
  QueryExecutionState,
  StartQueryExecutionCommand,
} from "@aws-sdk/client-athena";
import {
  OrganizationsClient,
  paginateListAccounts,
} from "@aws-sdk/client-organizations";
import { SendEmailCommand, SESClient } from "@aws-sdk/client-ses";
import formatDate from "date-fns/format";
import { logger } from "../../util/logger.js";
import { HTML_EMAIL_TEMPLATE, TEXT_EMAIL_TEMPLATE } from "./templates.js";

interface IAccount {
  arn: string;
  name: string;
  id: string;
}

interface IFinding {
  eventSource: string;
  eventName: string;
  numOccurrences: number;
}

const ONE_DAY_IN_MILLIS = 86400000;

const PURELY_NUMERIC_REGEX = /^[0-9]+$/;

/**
 * Use the built-in paginator in the AWS SDK v3 client to find all the accounts
 * in the organization. We'll include accounts in any status as we want to know
 * what access was attempted, even if the account is now suspended etc.
 *
 * If you make this service much more complicated, consider extracting this
 * method out into a class that the controller (Lambda handler) can invoke.
 *
 * @param client
 */
async function getAccounts(client: OrganizationsClient) {
  const listAccountsGenerator = paginateListAccounts({ client }, {});

  const accounts: IAccount[] = [];

  for await (const result of listAccountsGenerator) {
    (result.Accounts || []).forEach(account => {
      if (!account.Arn || !account.Name || !account.Id) {
        throw new Error(
          `Expected AWS to return accounts with an ARN, name and ID - got: ${JSON.stringify(
            account,
          )}`,
        );
      }

      accounts.push({
        arn: account.Arn,
        name: account.Name,
        id: account.Id,
      });
    });
  }

  return accounts;
}

/**
 * Run a query to find unauthorised access, wait for it to finish, throw if it
 * fails, return the results.
 *
 * @param client
 * @param database
 * @param catalog
 * @param workGroup
 * @param startDate
 * @param accountIds
 * @param enabledRegions
 */
async function queryForUnauthorisedAccess(
  client: AthenaClient,
  database: string,
  catalog: string,
  workGroup: string,
  startDate: string,
  accountIds: string[],
  enabledRegions: string[],
): Promise<IFinding[]> {
  const execution = await client.send(
    new StartQueryExecutionCommand({
      QueryString: `
        SELECT eventsource, eventname, COUNT(*) as num_occurrences
        FROM cloudtrail
        WHERE 1 = 1
        -- Only look at the last period
        AND timestamp >= '${startDate}'
        -- Cause Athena to look through each auto-generated partition
        AND account_id IN (
        ${accountIds
          .map(accountId => {
            if (!PURELY_NUMERIC_REGEX.exec(accountId)) {
              throw new Error(
                `Received account ID ${accountId} which doesn't look quite right and we don't want to SQL inject ourselves.`,
              );
            }

            return `'${accountId}'`;
          })
          .join(", ")}
        )
        AND region IN (${enabledRegions
          .map(region => `'${region}'`)
          .join(", ")})
        -- Exclude Config as it's very noisy
        AND sourceipaddress != 'config.amazonaws.com'
        -- Only denied requests
        AND errorcode IS NOT NULL
        AND (
            errorcode LIKE '%AccessDenied%'
         OR errorcode LIKE '%Forbidden%'
         OR errorcode LIKE '%Unauthorized%'
        )
        GROUP BY eventsource, eventname
        ORDER BY num_occurrences DESC;`,
      QueryExecutionContext: {
        Database: database,
        Catalog: catalog,
      },
      WorkGroup: workGroup,
    }),
  );

  let lastStatus: QueryExecutionState = QueryExecutionState.QUEUED;

  while (
    lastStatus === QueryExecutionState.QUEUED ||
    lastStatus === QueryExecutionState.RUNNING
  ) {
    const queryStatus = await client.send(
      new GetQueryExecutionCommand({
        QueryExecutionId: execution.QueryExecutionId,
      }),
    );

    lastStatus = queryStatus.QueryExecution!.Status!.State!;

    if (
      lastStatus === QueryExecutionState.FAILED ||
      lastStatus === QueryExecutionState.CANCELLED
    ) {
      throw new Error(`Querying Athena failed: ${JSON.stringify(queryStatus)}`);
    }
  }

  const results = await client.send(
    new GetQueryResultsCommand({
      QueryExecutionId: execution.QueryExecutionId,
    }),
  );

  return (results.ResultSet?.Rows || []).slice(1).map(row => {
    const [rawEventSource, rawEventName, rawNumOccurrences] = row.Data!;

    return {
      eventSource: rawEventSource.VarCharValue!,
      eventName: rawEventName.VarCharValue!,
      numOccurrences: parseInt(rawNumOccurrences.VarCharValue!, 10),
    };
  });
}

async function sendEmailReport(
  client: SESClient,
  source: string,
  destination: string,
  startDate: string,
  findings: IFinding[],
) {
  await client.send(
    new SendEmailCommand({
      Source: source,
      Destination: {
        ToAddresses: [destination],
      },
      Message: {
        Subject: {
          Data: "AWS unauthorised access report",
          Charset: "utf-8",
        },
        Body: {
          Text: {
            Data: TEXT_EMAIL_TEMPLATE({ findings, startDate }),
            Charset: "utf-8",
          },
          Html: {
            Data: HTML_EMAIL_TEMPLATE({ findings, startDate }),
            Charset: "utf-8",
          },
        },
      },
    }),
  );
}

export function buildHandler(
  athenaClient: AthenaClient,
  organizationsClient: OrganizationsClient,
  sesClient: SESClient,
  database: string,
  catalog: string,
  workGroup: string,
  enabledRegions: string[],
  emailSource: string,
  emailDestination: string,
) {
  return async function handler() {
    const startDate = new Date(new Date().getTime() - ONE_DAY_IN_MILLIS * 7);
    const formattedStartDate = formatDate(startDate, "yyyy/MM/dd");

    logger.info("querying for unauthorised access", { formattedStartDate });

    const accounts = await getAccounts(organizationsClient);

    logger.info("fetched accounts", { accounts });

    const findings = await queryForUnauthorisedAccess(
      athenaClient,
      database,
      catalog,
      workGroup,
      formattedStartDate,
      accounts.map(account => account.id),
      enabledRegions,
    );

    logger.info("retrieved findings", { findings });

    await sendEmailReport(
      sesClient,
      emailSource,
      emailDestination,
      formattedStartDate,
      findings,
    );

    logger.info("sent e-mail report - see you next time!");
  };
}
