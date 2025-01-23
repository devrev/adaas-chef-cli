# Tips
## Metadata tips

You are required to provide an external_domain_metadata file from your extractor, describing the logical schema of the external system.
The detailed format of this metadata is defined by the [following json-schema](external_domain_metadata_schema.json).

You can also find an [example](../demo/metadata.json).

A few points about it:

- The main purpose of the metadata is to define record types. Each record type should correspond to a homogenous set of records in the external system: a domain object that has a well-defined schema.

  In some cases this means simply declaring one record type for the api endpoints like '/comments' of the external system, but in other cases, external systems can have configurable custom types or subtypes (for example issuetypes in jira). In these cases the snap-in will need to query some API for the list of types, and produce a dynamic list of record_types in the metadata.

- The record_types don't have hierarchy, each is a leaf type, corresponding to concrete records in files marked with that itemtype. Record type categories can be used to group them, this serves two purposes:

  1. To be able to define mapping rules that apply to a dynamic set of record types, unknown at the time the snap-in is created
  2. To tell the recipe system that a record can transition between two records types while preserving its identity.

- The filed type 'int' is used to represent integer numeric values. In certain external systems identifiers of records or enum values are also stored as intergers. These are however not 'conceptually integers' in airdrops perpective.
  The natural format of integers is `null` | json numbers without decimals.
  Numbers encoded to strings (eq `"2112"`), or empty strings should not be used.

- The primary key (id) of the record in the external system doesn't need to be declared as a field in the record type. Instead, id and created_date and modified_date has to be provided on the top level, and all other fields inside the data field. An example extracted record might look like this:

```json
{
  "id": "2102e01F",
  "operation": "created",
  "created_date": "1970-01-01T01:00:04+01:00",
  "modified_date": "1972-03-29T22:04:47+01:00",
  "data": {
    "actual_close_date": "1970-01-01T02:33:18+01:00",
    "created_date": "1970-01-01T01:08:25+01:00",
    "modified_date": "1970-01-01T01:00:08+01:00",
    "owner": "3A",
    "priority": "P1",
    "target_close_date": null,
    "title": "Something"
  }
}
```

- All logical data types can be modified to be a collection instead.
  The natural format of a collection is a json array (or null), containing the natural format of its elements, for example:

  ```json
  {
    "reporter_ids": [
      {
        "ref_type": "user",
        "id": "2103232131",
        "fallback_record_name": "John Wick"
      },
      {
        "ref_type": "contact",
        "id": "2103232144",
        "fallback_record_name": "Lara Croft"
      }
    ],
    "tags": ["bug", "good-first-issue"]
  }
  ```

  Some systems provide collections that are enum values for references in a string, separated by some separator (for example comma or semicolon), eg:

  ```json
  {
    "reporter_ids": "2103232131,2103232144",
    "tags": "bug;good-first-issue"
  }
  ```

  This should be avoided, and the data normalized to the natural format in the extractor.

- Structs are embedded json objects inside the given field. They are meant to represent data that consists of multiple elements naturally belonging together, for example a phone number or an address, but doesn't form its own record with identity.
  
  These are specifically helpful in case the whole struct is optional/nullable, but some of its fields are required.
  In this case the structs provide a cleaner representation that flattening it to the object containing it, and then applying some kind of conditional requiredness conditions.
  Example:

  ```json
  {
    "address": {
      "country": "US",
      "state": "TX",
      "city": "Austin",
      "address_line": "Rocket Road 1"
    },
    "phone_number": null
  }
  ```

  Many systems resolve references to embedded structs, for example:

  ```json
  {
    "creator": {
      "userId": "2103232144",
      "name": "Lara Croft",
      "role": "Adventurer",
      "email": "tomb@raider.com"
    }
  }
  ```

  Such 'detailed references' are not meant to be declared as structs in airdrop. They should be transformed either to be just a simple id reference, or a dynamically typed reference with exactly the fields id, fallback_record_name and ref_type.
  Therefore using references and structs inside structs is currently not supported.

- In general, any fields in the metadata not otherwise mapped will be offered to the end user as custom fields, no additional effort needed. 

## Troubleshooting

- Check if chef-cli version is up to date. You can find the version you are using with `chef-cli --version` and the latest available version under project releases.

- You can find the logs for the snap-in package with the following command:
  ```bash
  devrev snap_in_package logs
  ```
