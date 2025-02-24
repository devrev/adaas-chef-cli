# Supported types 

Refer to the [metadata schema](../external_domain_metadata_schema.json) to help choose appropriate type for your fields.

DevRev supports the following types:

- `bool`

- `int`

- `float`

- `text`
  - Text to be interpreted as plain text.

- `rich_text`
  - Rich text is used in DevRev to represent text fields that can be formatted and can contain mentions. Eg.: description of an issue, body of a conversation, etc.
  - A simple rich text looks like one markdown string wrapped in an array: `["Hello **world**!"]`.
    Markdown should be compatible with [CommonMark Spec v0.30](https://spec.commonmark.org/0.30).
  - To support mentions `rich_text` can be formatted as an array of strings and mention objects and the field should use the `use rich text` transformation method.
  - Example of a simple mention object:  
    ```json
    [
      "Hello ", 
      {"ref_type":"external_user_type", "id":"1...", "fallback_record_name": "John Smith"}, 
      "how are you?"
    ]
    ```
  - Mention represents any mention (user, issue, etc.) in rich text and is defined as:
      | Field                  | Type   | Required | Description                                                                                                                          |
      | ---------------------- | ------ | -------- | ------------------------------------------------------------------------------------------------------------------------------------ |
      | `id`                   | String | Yes      | Identifier of the item being mentioned. This could be a user ID or any other identifier, in the format used by the source system.    |
      | `ref_type`             | String | Yes      | Type of the item being mentioned. Examples include "issue", "comment", etc. The recipe will convert this according to user mappings. |
      | `fallback_record_name` | String | No       | The text to display if the mention cannot be resolved. This could be a user's display name or a ticket title, for instance.          |
  - In reverse loaders should expect the following structure:
    ```json
    {
      "type": "rich_text",
      "content": [
        "Hello ",
        {
          "ref_type": "external_user_type",
          "id": "don:...",
          "fallback_record_name": "John Smith"
        },
        "how are you?"
      ]
    }
    ```
  - Articles support Markdown as well as HTML. For more details, refer to [article references](article_references.md).

- `reference`: IDs referring to another record. References have to declare what they can refer to,
  which can be one or more record types (`#record:`) or categories (`#category:`).

- `enum`: A string from a predefined set of values with the optional human-readable names for each value.

- `date`

- `timestamp`

- `struct`

- `permission`: A special structure associating a reference to an user-like record type (the field `member_id`) with an enum value that can be interpreted as the role or permission level associated with that user. This is useful in a few cases when mapping fields with the same type in DevRev.
