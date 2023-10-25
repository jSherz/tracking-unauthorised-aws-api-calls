import { AthenaClient } from "@aws-sdk/client-athena";
import { buildHandler } from "./handler.js";
import { OrganizationsClient } from "@aws-sdk/client-organizations";
import { SESClient } from "@aws-sdk/client-ses";
import { tracer } from "../../util/tracer.js";

const DATABASE = process.env.DATABASE;
const WORK_GROUP = process.env.WORK_GROUP;
const CATALOG = process.env.CATALOG;
const ENABLED_REGIONS = process.env.ENABLED_REGIONS;
const EMAIL_SOURCE = process.env.EMAIL_SOURCE;
const EMAIL_DESTINATION = process.env.EMAIL_DESTINATION;

if (
  !DATABASE ||
  !WORK_GROUP ||
  !CATALOG ||
  !ENABLED_REGIONS ||
  !EMAIL_SOURCE ||
  !EMAIL_DESTINATION
) {
  throw new Error(
    "You must specify DATABASE, WORK_GROUP, CATALOG, ENABLED_REGIONS, EMAIL_SOURCE and EMAIL_DESTINATION environment variables.",
  );
}

const athenaClient = tracer.captureAWSv3Client(new AthenaClient({}));

const organizationsClient = tracer.captureAWSv3Client(
  new OrganizationsClient({}),
);

const sesClient = tracer.captureAWSv3Client(new SESClient({}));

export const handler = buildHandler(
  athenaClient,
  organizationsClient,
  sesClient,
  DATABASE,
  CATALOG,
  WORK_GROUP,
  ENABLED_REGIONS.split(","),
  EMAIL_SOURCE,
  EMAIL_DESTINATION,
);
