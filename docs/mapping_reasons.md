# Reasons why some mappings might be unavailable

There are several reasons why some mappings might be unavailable. We use transformation methods to map data from one format to another. These methods work on field scope and each have their own requirements. If the data does not meet these requirements, the mapping will not be available.

1. A common reason is mismatch of types. For example, if a DevRev field is expected to be `rich_text`, but the field is set as `text` mapping to some fields will be unavailable. Refer to the [supported types](supported_types.md) section and the general DevRev documentation for more information.

2. Only references can be mapped to references. Ensure that source system fields are correctly mapped to reference fields in DevRev.

3. Currently, support for the `struct` type is limited. Marking a field as a struct in the metadata schema will make it unavailable for mapping outside of using the custom jq transformation method. Refer to the [metadata tips](tips.md#metadata-tips) for more information.

4. Links are supported only on works and conversations.

We provide the following transformation methods for custom fields:
1. `make_constrained_simple_value` a simple method that along with mapping allows you to propagate validation constraints from the external system and enforces those in DevRev
2. `make_enum` produces an enum field, where external field should be of type enum
3. `make_uenum` produces an enum field, where external field should be of type enum
4. `reference_custom_field` produces a reference field, where external field should be of type reference

We provide the following transformation methods for stock fields:
1. `make_custom_stages` makes custom stages in accordance with the stage diagram data provided in the domain metadata
2. `map_enum` produces an enum field, where external field should be of type enum
3. `map_roles` maps permission roles from external to DevRev format
4. `use_as_array_value` produces an array field from a scalar (single-value) external field
5. `use_devrev_record` enables use of a fixed reference to something in DevRev, where Don should be of right type
6. `use_directly` is the identity operator, it returns exactly the input, where external field should be of the same type as the DevRev field. If external field is an array (is marked as collection) internal field has to be an array as well.
7. `use_fixed_value` produces a fixed value in DevRev, which is useful to map required DevRev fields if source system doesn't have an equivalent field. Only available for boolean or enum DevRev fields

We provide the following transformation methods for both custom and stock fields:
1. `use_rich_text` produces a rich text field, where external field should be of type rich_text

We provide the following transformation methods for constructed custom fields:
1. `construct_text_field` produces a text field, where external field should be of type text


`use_raw_jq` can be used on all fields. It enables the use of `jq` to transform data and should be used sparingly if no other transformation method is available.
