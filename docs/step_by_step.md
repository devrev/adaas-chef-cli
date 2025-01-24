# Step by step guide

## Define external domain metadata.

The purpose of the metadata is to inform airdrop about the logical domain model of the external system, that is, to tell us what kind of _external_record_types_ are there, and what are their relationships, and what the type, human readable name, and other metadata of the fields are.

Your extractor snap-in will be required to provide this metadata as an extracted json file with the item type of 'external_domain_metadata'. The format of this file is defined by the [following json-schema](../external_domain_metadata_schema.json).

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

3. Inspect the generated metadata, check if its field types are correct (see below on the detailed description of the supported field types), and consider the todo-s and suggestions the tool generates.

Tips for best results:

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
this can be defined by the `are_record_type_conversions_possible` field in the `record_type_categories` section. For example, if
an issue that can be moved to become a problem in the external system.

```json
{
  "schema_version": "v0.2.0",
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
      "are_record_type_conversions_possible": true
    }
  }
}
```

5. Declare fields for each record type:

Fields' keys must match what is actually found in the extracted data in the artifacts.

The **supported types** are explained in-depth on the [supported types page](supported_types.md).

If the external system supports custom fields, the set of custom fields in each record type you wish to extract must be
declared too.

Enum fields set of possible values can often be customizable. A good practice is to retrieve the set of possible values
for all enum fields from the external system's APIs in each sync run.

`ID` (primary key) of the record, `created_date`, and `modified_date` must not be declared.

Example:

```json
{
  "schema_version": "v0.2.0",
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
Note, field keys are case-sensitive.

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

External system fields that shouldn't be mapped in reverse should be marked as `is_read_only`. Depending on their purpose you can also mark fields as `is_indexed`, `is_identifier`, `is_filterable`, `is_write_only` etc. By default these will be set to false. You can find the full list of supported field attributes and their descriptions in the [metadata schema](../external_domain_metadata_schema.json#L160). 

7. Consider special references:

- Some references have role of parent or child. This means that the child record doesn't make sense without its parent, for example a comment attached to a ticket. Assigning a `reference_type` helps Airdrop correctly handle such fields in case the end-user decides to filter some of the parent records out.

- Sometimes the external system uses references besides the primary key of records, for example when referring to a case by serial number, or to a user by their email. To correctly resolve such references, they must be marked with 'by_field', which must be a field existing in that record type, marked 'is_identifier'. For example:

```json
{
  "schema_version": "v0.2.0",
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
    "all_transitions_allowed": false,
    "stages": {
      "detected": {
        "transitions_to": ["mitigated", "archived", "rca_ready"],
        "state": "new"
      },
      "mitigated": {
        "transitions_to": ["archived", "detected"],
        "state": "work_in_progress"
      },
      "rca_ready": {
        "transitions_to": ["archived"],
        "state": "work_in_progress"
      },
      "archived": {
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
      }
    }
  }
}
```

In the above example, the status field is declared the controlling field of the stage diagram, which then specifies the transitions for each stage.  
It is possible that the status field has no explicit transitions defined but one would still like to create a stage diagram in DevRev. In that case you should use set the `all_transitions_allowed` field to `true`, which will create a diagram where all the defined stages can transition to each other.  
The external system might have a way to categorize statuses (such as status categories in Jira). These can also be included in the diagram metadata (`states` in the example above) which will create them in DevRev and they can be referenced by the stages. This is entirely optional and in case the `states` field is not provided, default DevRev states will be used, those being `open`, `in_progress` and `closed`. If there is a way, the developer can categorize the stages to one of these three, or leave it up to the end user.  
The `starting_stage` field defines the starting stage of the diagram, in which all new instances of the object will be created. This data should always be provided if available, otherwise the starting stage will be selected alphabetically.

In the current (v0.2.0) metadata format, it is no longer necessary to assign ordinal and stage_name to stages, the order and the human-readable name will be taken from the enum values defined on the controlling field.

## Normalize data

During the data extraction phase, the snap-in uploads batches of extracted items (the recommended batch size is 2000 items) formatted in JSONL
(JSON Lines format), gzipped, and submitted as an artifact to S3Interact (with tooling from `@devrev/adaas-sdk`).

Each artifact is submitted with an `item_type`, defining a separate domain object from the external system and matching the `record_type` in the provided metadata.
Item types defined when uploading extracted data must validate the declarations in the metadata file.

Extracted data must be normalized.

- Null values: All fields without a value should either be omitted or set to null. For example, if an external system provides values such as "", -1 for missing values, those must be set to null.
- Timestamps: Full-precision timestamps should be formatted as RFC3399 (`1972-03-29T22:04:47+01:00`), and dates should be just `2020-12-31`.
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

Validate extracted artifacts using the following command (example for record type `issues`):

```bash
chef-cli validate-data -m external_domain_metadata.json -r issue < extractor_issues_2.json
```

You can also generate example data to show the format the data has to be normalized to, using:

```bash
echo '{}' | chef-cli fuzz-extracted -r issue -m external_domain_metadata.json > example_issues.json
```

## Deploy your snap-in in your test org, and run an import

Relevant documentation can be found in the [DevRev documentation](https://developer.devrev.ai/public/snapin-development/locally-testing-snap-ins) and in [adaas-template repository](https://github.com/devrev/adaas-template). 

To deploy the snap-in, run `make auth` and `make deploy` in the snap-in repository. To activate the snap-in, run `devrev snap_in activate`. You can now create an import in the DevRev UI.

The import will reach 'waiting for user input' stage. Wait there.

## Complete the chef-cli initial domain mapping setup

Next, continue with the steps outlined in [chef-cli setup](initial_domain_mapping_setup.md). 

When you are done you should have the chef-cli context set up and have the chef-cli local UI running in your browser.

## Use the local UI to create initial domain mappings

The final artifact of the recipe creation process is the `initial_domain_mapping.json`, which has to be embedded in the extractor.

This mapping, unlike the recipe blueprint of a concrete import, can contain multiple options for each external record type from which the end-user might choose (for example allow 'task' from an external system to map either to issue or ticket in DevRev), and it can contain also mappings that apply to a record type category. When the user runs a new import, and the extractor reports in its metadata record types belonging to this category, that are not directly mapped in the initial domain mappings, the recipe manager will apply the per-category default to them.

After the blueprint of the test import was completed, the 'install in this org' button takes you to the initial domain mapping creation screen, where you can 'merge' the blueprint to the existing initial mappings of the org.

By repeating this process (run a new import, create a different configuration, merge to the initial mappings), you can create an initial mapping that contains multiple options for the user to choose from.

Finally the Export button allows you to retrieve the `initial_domain_mapping.json`.

## Tip: use local metadata in the local UI

You can also provide a local metadata file to the command using the '-m' flag for example: `chef-cli configure-mappings --env prod -m metadata.json`, this enables to use:

- raw jq transformations using an external field as input. (This is an experimental feature)

- filling in example input data for trying out the transformation.

In this case it is not validated that the local file is the same as the one submitted by the snap-in, this has to be ensured by you.

## Test an import with initial mapping using the in-app UI.

Once the initial mappings are prepared and, any new import in the org (with the same snap-in slug and import slug) where they are installed will use them. The end-users can influence the recipe blueprint that gets created for the sync unit trough the mapping screen in the UI, where they can make record-type filtering, mapping, fine grained filtering, low-code field and value mapping, and finally custom field filtering.

Their decisions are constrained by the choices provided in the initial domain mappings. Currently the low-code UI offers limited insight into the mappings and their reasons, and in some cases, mismatches arise when something that worked in chef-cli doesn't offer the right options to the user, or not all fields that should be resolved are solved. To assist debugging such cases, chef-cli provides a command to extract the description of the low-code decisions that are asked in the UI. Please provide this to us when reporting an issue with how the end-user mapping UI behaves.

```bash
chef-cli low-code --env prod > low_code.json`
```
 
## Read metadata tips to improve the metadata

See the [metadata tips](tips.md) section for more information on how to improve the metadata.
