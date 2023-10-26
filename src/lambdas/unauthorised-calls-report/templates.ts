import * as handlebars from "handlebars";

export const HTML_EMAIL_TEMPLATE =
  handlebars.compile(`Here's a report of unauthorised AWS access since {{startDate}}:

<table style="border: solid 1px #666">
  <thead>
  <th style="background-color: #ccc; border: solid 1px #666; padding: 4px">event source (service)</th>
  <th style="background-color: #ccc; border: solid 1px #666; padding: 4px">event name</th>
  <th style="background-color: #ccc; border: solid 1px #666; padding: 4px">number of occurrences</th>
  </thead>

  <tbody>
  {{#each findings}}
    <tr>
      <td style="border: solid 1px #666; padding: 4px">
        {{eventSource}}
      </td>
      <td style="border: solid 1px #666; padding: 4px">
        {{eventName}}
      </td>
      <td style="border: solid 1px #666; padding: 4px">
        {{numOccurrences}}
      </td>
    </tr>
  {{/each}}
  </tbody>
</table>
`);

export const TEXT_EMAIL_TEMPLATE =
  handlebars.compile(`Here's a report of unauthorised AWS access since {{startDate}}:

event source (service),event name,number of occurrences
{{#each findings}}
{{eventSource}}{{eventName}}{{numOccurrences}}
{{/each}}
`);
