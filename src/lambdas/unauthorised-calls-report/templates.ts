import * as handlebars from "handlebars";

export const HTML_EMAIL_TEMPLATE =
  handlebars.compile(`Here's a report of unauthorised AWS access since {{startDate}}:

<table>
  <thead>
  <th>event source (service)</th>
  <th>event name</th>
  <th>number of occurrences</th>
  </thead>

  <tbody>
  {{#each finding}}
    <tr>
      <td>
        {{eventSource}}
      </td>
      <td>
        {{eventName}}
      </td>
      <td>
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
{{#each finding}}
{{eventSource}}{{eventName}}{{numOccurrences}}
{{/each}}
`);
