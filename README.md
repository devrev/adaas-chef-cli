# chef-cli

DevRev auxiliary CLI for ADaaS recipe development

General ADaaS documentation: https://developer.devrev.ai/snapin-development/adaas/overview

## Step by step guide

## Install the chef-cli

A cli tool is provided to assist you in this repo. Select the binary appropriate for your operating system, and install it in your path (or just remember its location). In the following steps we will assume it is available as `$ chef-cli`

To install auto-completions on Linux or Mac, you can run:

```bash
./install_completions.sh
```

And restart your shell.

We support Bash and ZSH. Make sure to run the script from project home directory.

To install PowerShell auto-completions, first run `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass`. Then open the PowerShell profile (with `code $profile` or `notepad $profile`) and add this line (make sure to replace `/path/to/this/repo` with the path to this repository):

```text
/path/to/this/repo/autocomplete/chef-cli.ps1
```

## Define external domain metadata.

The purpose of the metadata is to inform airdrop about the logical domain model of the external system, that is, to tell us what kind of _external_record_types_ are there, and what are their relationships, and what the type, human readable name, and other metadata of the fields are.

Your extractor snapin will be required to provide this metadata as an extracted json file with the item type of 'external_domain_metadata'. The format of this file is defined by the [following json-schema](external_domain_metadata_schema.json).

To check the metadata for internal consistency, you should use the following command after every step:

`$ chef-cli validate-metadata < metadata.json`
This will output any problems there may be with the metadata file.


## Getting a good starting point metadata using the infer-metadata command

`$ chef-cli infer-metadata example_data_directory > metadata.json`

1. Collect example data from the external system, and place them in a directory. Each file should:
  - Contain the same type of records, named after their type.
  - Have .json or .jsonl extension, for example `issues.json`
  - Contain either a single json array of objects, or newline-separated objects.

2. Run `$ chef-cli infer-metadata example_data_directory`, replacing example_data_directory with the relative path to this directory.

3. Inspect the generated metadata, check if its field types are correct (see below on the detailed description of the supported field types), and condier the todo's and suggestions the tool generates.

Tips for ther best results:

	- It is recommended to provide 10-100 examples (but definitely not more than 1000) of each record type to get a good guess. (too few examples may result in not all relevant pattern being detected, too many examples may result in low performance).
  - The logically distinct fields of the record should be separate keys on the top-level.
  - It is ideal if example data is referentially consistent, allowing us to guess what field refers to what by comparing the sets of IDs. This means it is better to extract a complete but small set of data, instead of sampling randomly from a system with a lot of data.
  - The IDs should be strings, not numbers.

This example metadata can be used to prototype initial domain mappings (by running a sync with it) and to generate example normalized data, but it is still just a guess: It has to be reviewed and refined.

## Step-by-step approach to crafting the metadata declaration

Since crafting metadata declaration in the form of an `external_domain_metadata.json` file can be a tedious process, a step-by-step
approach is useful for understanding the metadata declarations and as a checklist to declare the metadata for an extraction from a specific external system.

Metadata declarations include both _static declarations_, formulated by deduction and comparison of external domain system,
and DevRev domain system and _dynamic declarations_ that are obtained during a snap-in run from external system APIs
(since they are configurable in the external system and can be changed by the end user at any time, such as
mandatory fields or custom fields).

1. Declare the extracted record types

_Record types_ are the types of records that has a well-defined schema you extract from or load to the external system, a domain object in the external system.

If the snap-in is extracting issues and comments, a good starting point to declare record types in `external_domain_metadata.json` would be:

```json
{
  "record_types": {
    "issues": {},
    "comments": {}
  }
}
```

Although the declaration of record types is arbitrary, they must match the `item_type` field in the artifacts you will upload.

2. Declare the custom record types

If the external system supports custom types, or custom variants of some base record type, and you want to airdrop those
too, you have to declare them in the metadata at runtime. That is, the extractor will use APIs of the external system to
dynamically discover what custom record types exist.

The output of this process might look like this:

```json
{
  "record_types": {
    "issues_stock_epic": {},
    "issues_custom2321": {},
    "issues_custom2322": {},
    "comments": {}
  }
}
```

3. Provide human-readable names to external record types

Define human-readable names for the record types defined in your metadata file.

```json
{
  "record_types": {
    "issues_stock_epic": {
      "name": "Epic"
    },
    "issues_custom2321": {
      "name": "Incident report"
    },
    "issues_custom2322": {
      "name": "Problem"
    },
    "comments": {
      "name": "Comment"
    }
  }
}
```

4. Categorize external record types.

The metadata allows each external record type to be annotated with one category. The category key can be an arbitrary
string, but it must match the categories declared under `record_type_categories`.

Categories of external record types simplify mappings so that a mapping can be applied to a whole category of record types.
Categories also provide a way how custom record types can be mapped.

If the external system allows records to change the record type within the category, while still preserving identity,
this can be defined by the `are_transitions_possible` field in the `record_type_categories` section. For example, if
an issue that can be moved to become a problem in the external system.

```json
{
  "record_types": {
    "issues_stock_epic": {
      "name": "Epic",
      "category": "issue"
    },
    "issues_custom2321": {
      "name": "Incident report",
      "category": "issue"
    },
    "issues_custom2322": {
      "name": "Problem",
      "category": "issue"
    },
    "comments": {
      "name": "Comment"
    }
  },
  "record_type_categories": {
    "issue": {
      "are_transitions_possible": true
    }
  }
}
```

5. Declare fields for each record type:

Fields' keys must match what is actually found in the extracted data in the artifacts.

The supported types are:

- `bool`
- `int`
- `float`
- `text`
- `rich_text`: Formatted text with mentions and images.
- `reference`: IDs referring to another record. References have to declare what they can refer to,
  which can be one or more record types (`#record:`) or categories (`#category:`).
- `enum`: A string from a predefined set of values with the optional human-readable names for each value.
- `date`,
- `timestamp`,
- `struct`

- `permission`: A special strucuture associating a reference to an user-like record type (the field `member_id`) with an enum value that can be interpreted as the role or permission level associated with that user. This is useful in a few cases when mapping fields with the same type in devrev.

If the external system supports custom fields, the set of custom fields in each record type you wish to extract must be
declared too.

Enum fields set of possible values can often be customizable. A good practice is to retrieve the set of possible values
for all enum fields from the external system's APIs in each sync run.

`ID` (primary key) of the record, `created_date`, and `modified_date` must not be declared.

Example:

```json
{
  "record_types": {
    "issues_stock_epic": {
      "name": "Epic",
      "category": "issue",
      "fields": {
        "actual_close_date": {
          "name": "Closed at",
          "type": "timestamp"
        },
        "owner": {
          "is_required": true,
          "type": "reference",
          "reference": {
            "refers_to": {
              "#record:user": {}
            }
          }
        },
        "creator": {
          "is_required": true,
          "type": "reference",
          "reference": {
            "refers_to": {
              "#record:user": {}
            }
          }
        },
        "priority": {
          "name": "Priority",
          "is_required": true,
          "type": "enum",
          "enum": {
            "values": [
              {
                "key": "P-0",
                "name": "Super important"
              },
              {
                "key": "P-1"
              },
              {
                "key": "P-2",
                "is_deprecated": true
              }
            ]
          }
        },
        "target_close_date": {
          "type": "date"
        },
        "headline": {
          "name": "Headline",
          "is_required": true,
          "type": "text"
        }
      }
    }
  }
}
```

6. Declare arrays

If the field is array in the extracted data, it is still typed with the one of the supported types. Lists must be marked as a `collection`.

```json
{
  "name": "Assignees",
  "is_required": true,
  "type": "reference",
  "reference": {
    "refers_to": {
      "#category:agents": {}
    }
  },
  "collection": {
    "max_length": 5
  }
}
```

7. Consider special references:

- Some references have role of parent or child. This means that the child record doesn't make sense without its parent, for example a comment attached to a ticket. Assigning a `role` helps Airdrop correctly handle such fields in case the end-user decides to filter some of the parent records out.

- Sometimes the external system uses references besides the primary key of records, for example when referring to a case by serial number, or to a user by their email. To correctly resolve such references, they must be marked with 'by_field', which must be a field existing in that record type, marked 'is_identifier'. For example:

```json
{
  "record_types": {
    "users": {
      "fields": {
        "email": {
          "type": "text",
          "is_identifier": true
        }
      }
    },
    "comments": {
      "fields": {
        "user_email": {
          "type": "reference",
          "reference": {
            "refers_to": {
              "#record:users": {
                "by_field": "email"
              }
            }
          }
        }
      }
    }
  }
}
```

8. Consider state transitions

If an external record type has some concept of states, between which only certain transitions are possible, (eg to move to the 'resolved' status, an issue first has to be 'in_testing' and similar business rules), you can declare these in the metadata too.

This will allow us to create a matching 'stage diagram' (a collection of stages and their permitted transitions) in DevRev, which will usually allow a much simpler import and a closer preservation of the external data than needing to map to DevRev's builtin (stock) stages.

This is especially important if two-way sync will eventually be needed, as setting the transitions up correctly ensures that the transitions the record undergo in DevRev will be able to be replicated in the external system.

To declare this in the metadata, ensure the status is represented in the extracted data as an enum field, and then declare the allowed transitions (which you might have to retrieve from an API at runtime, if they are also customized).

```json
{
  "fields": {
    "status": {
      "name": "Status",
      "is_required": true,
      "type": "enum",
      "enum": {
        "values": [
          {
            "key": "detected",
            "name": "Detected"
          },
          {
            "key": "mitigated",
            "name": "Mitigated"
          },
          {
            "key": "rca_ready",
            "name": "RCA Ready"
          },
          {
            "key": "archived",
            "name": "Archived"
          }
        ]
      }
    }
  },
  "stage_diagram": {
    "controlling_field": "status",
    "starting_stage": "detected",
    "no_transitions_defined": false,
    "stages": {
      "detected": {
        "stage_name": "Detected",
        "transitions_to": ["mitigated", "archived", "rca_ready"],
        "state": "new"
      },
      "mitigated": {
        "stage_name": "Mitigated",
        "transitions_to": ["archived", "detected"],
        "state": "work_in_progress"
      },
      "rca_ready": {
        "stage_name": "RCA Ready",
        "transitions_to": ["archived"],
        "state": "work_in_progress"
      },
      "archived": {
        "stage_name": "Archived",
        "transitions_to": [],
        "state": "completed"
      }
    },
    "states": {
      "new": {
        "name": "New"
      },
      "work_in_progress": {
        "name": "Work in Progress"
      },
      "completed": {
        "name": "Completed",
        "is_end_state": true
      },
    }
  }
}
```

In the above example, the status field is declared the controlling field of the stage diagram, which then specifies the transitions for each stage.  
It is possible that the status field has no explicit transitions defined but one would still like to create a stage diagram in DevRev. In that case you should use set the `no_transitions_defined` field to `true`, which will create a diagram where all the defined stages can transition to each other.  
The external system might have a way to categorize statuses (such as status categories in Jira). These can also be included in the diagram metadata (`states` in the example above) which will create them in DevRev and they can be referenced by the stages. This is entirely optional and in case the `states` field is not provided, default DevRev states will be used, those being `open`, `in_progress` and `closed`. If there is a way, the developer can categorize the stages to one of these three, or leave it up to the end user.  
The `starting_stage` field defines the starting stage of the diagram, in which all new instances of the object will be created. This data should always be provided if available, otherwise the starting stage will be selected alphabetically.

## Normalize data

During the data extraction phase, the snap-in uploads batches of extracted items (the recommended batch size is 2000 items) formatted in JSONL
(JSON Lines format), gzipped, and submitted as an artifact to S3Interact (with tooling from `@devrev/adaas-sdk`).

Each artifact is submitted with an `item_type`, defining a separate domain object from the external system and matching the `record_type` in the provided metadata.
Item types defined when uploading extracted data must validate the declarations in the metadata file.

Extracted data must be normalized.

- Null values: All fields without a value should either be omitted or set to null. For example, if an external system provides values such as "", -1 for missing values, those must be set to null.
- Timestamps: Full-precision timestamps should be formatted as RFC3999 (`1972-03-29T22:04:47+01:00`), and dates should be just `2020-12-31`.
- References: references must be strings, not numbers or objects.
- Number fields must be valid JSON numbers (not strings)
- Multiselect fields must be provided as an array (not CSV)

Each line of the file contains an `id` and the optional `created_date` and `modified_date` fields in the beginning of the record.
All other fields are contained within the `data` attribute.

```json
{
  "id": "2102e01F",
  "created_date": "1972-03-29T22:04:47+01:00",
  "modified_date": "1970-01-01T01:00:04+01:00",
  "data": {
    "actual_close_date": "1970-01-01T02:33:18+01:00",
    "creator": "b8",
    "owner": "A3A",
    "rca": null,
    "severity": "fatal",
    "summary": "Lorem ipsum"
  }
}
```

Extracted artifacts can be validated with the `chef-cli` using the following command:

```bash
$ chef-cli validate-data -m external_domain_metadata.json -r issue < extractor_issues_2.json
```

You can also generate example data to show the format the data has to be normalized to, using:

```bash
$ echo '{}' | chef-cli fuzz-extracted -r issue -m external_domain_metadata.json > example_issues.json
```

## Deploy your snapin in your test org, and run an import.

This will reach 'waiting for user input' stage. Wait there.

## Initialize the context of the sync:

To allow the cli to work in the context of that sync, you have to provide its identifying properties in an environment variable (replacing the values based on the logs of your running import)

```bash
export AIRDROP_CONTEXT='{"run_id":"1","mode":"initial","connection_id":"x","migration_unit_id":"0716","dev_org_id":"DEV-1kA79wWrRR","dev_user_id":"DEVU-1","source_id":"07-16","source_type":"ADaaS","source_unit_id":"x","source_unit_name":"x","import_slug":"x","snap_in_slug":"x"}'
```

Or you can use the interactive helper of the cli:

```bash
$ eval $(chef-cli ctx init); chef-cli ctx show > ctx.json
```

## Add your token as an environment variable:

Obtain a PAT-token from the Settings/Account tab of the devorg where you deploy your snapin, and export is at DEVREV_TOKEN

## Use the local UI to create a recipe blueprint for your initial import:

`$ chef-cli configure-mappings --env prod`

If your org is no in US-East-1, you have to override an environment variable to make sure the tool reaches to the right server, eg:

```bash
ACTIVE_PARTITION=dvrv-in-1 chef-cli configure-mappings --env prod
```

where the options are:
"dvrv-us-1"
"dvrv-eu-1"
"dvrv-in-1"
"dvrv-de-1"

The first function of the local UI is to assemble a 'blueprint' for concrete import running in the test-org, allowing the mapping to be tested out and evaluated.
After it is used for the import, the mappings become immutable, but the chef-cli UI offers a button to make a draft clone, which can be edited again for refinements.

## Use the local UI to create an initial domain mappings

The final artifact of the recipe creation process is the initial_domain_mappings.json, which has to embedded in the extractor.

This mapping, unlike the recipe blueprint of a concrete import, can contain multiple options for each external record type from which the end-user might choose (for example allow 'task' from an external system to map either to issue or ticket in devrev), and it can contain also mappings that apply to a record type category. When the user runs a new import, and the extractor reports in its metadata record types belonging to this category, that are not directly mapped in the initial domain mappings, the recipe manager will apply the per-category default to them.

After the blueprint of the test import was completed, the 'install in this org' button takes you to the initial domain mapping creation screen, where you can 'merge' the blueprint to the existing initial mappings of the org.

By repeating this process (run a new import, create a different configuration, merge to the initial mappings), you can create an initial mapping that contains multiple options for the user to choose from.

Finally the Export button allows you to retrieve the initial_domain_mapping.json.

## Tip: use local metadata in the local UI

You can also provide a local metadata file to the command using the '-m' flag for example: `chef-cli configure-mappings --end dev -m metadata.json`, this enables to use:

- raw jq transformations using an external field as input. (This is an experimental feature)

- filling in example input data for trying out the transformation.

In this case it is not validated that the local file is the same as the one submitted by the snapin, this has to be ensured by you.

## Test an import with initial mapping using the in-app UI.

Once the initial mappings are prepared and, any new import in the org (with the same snapin slug and import slug) where they are installed will use them. The end-users can influence the recipe blueprint that gets created for the sync unit trough the mapping screen in the UI, where they can make record-type filtering, mapping, fine grained filtering, low-code field and value mapping, and finally custom field filtering.

Their decisions are constrained by the choices provided in the initial domain mappings. Currently the low-code UI offers limited insight into the mappings and their reasons, and in some cases, mismatches arise when something that worked in chef-cli doesn't offer the right options to the user, or not all fields that should be resolved are solved. To assist debugging such cases, chef-cli provides a command to extract the description of the low-code decisions that are asked in the UI. Please provide this to us when reporting an issue with how the end-user mapping UI behaves.

```bash
chef-cli low-code --env prod > low_code.json`
```

## Metadata tips

You are required to provide an external_domain_metadata file from your extractor, describing the logical schema of the external system.
The detailed format of this metadata is defined by the [following json-schema](external_domain_metadata_schema.json).

You can also find an [example](demo/metadata.json).

A few points about it:

- The main purpose of the metadata is to define record types. Each record type should correspond to a homogenous set of records in the external system: a domain object that has a well-defined schema.
  In some cases this means simply declaring one record type for the api endpoints like '/comments' of the external system, but in other cases, external systems can have configurable custom types or subtypes (for example issuetypes in jira). In these cases the snapin will need to query some API for the list of types, and produce a dynamic list of record_types in the metadata.

- The record_types don't have hierarchy, each is a leaf type, corresponding to concrete records in files marked with that itemtype. Record type categories can be used to group them, this serves two purposes:

1. To be able to define mapping rules that apply to a dynamic set of record types, unknown at the time the snapin is created
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
