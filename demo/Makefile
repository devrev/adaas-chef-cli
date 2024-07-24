.DELETE_ON_ERROR:

metadata-problems: metadata.json
	chef-cli validate-metadata < metadata.json > $@

comment.json: metadata-problems fuzz_config.json
	chef-cli fuzz-extracted -r comment -m metadata.json -s 0 < fuzz_config.json > $@

issue.json: metadata-problems
	chef-cli fuzz-extracted -r issue -m metadata.json -s 0 < fuzz_config.json > $@

user.json: metadata-problems
	chef-cli fuzz-extracted -r user -m metadata.json -s 0 < fuzz_config.json > $@

incident.json: metadata-problems
	chef-cli fuzz-extracted -r incident -m metadata.json -s 0 < fuzz_config.json > $@

data-problems: comment.json issue.json user.json metadata.json incident.json
	chef-cli validate-data -m metadata.json -r issue < issue.json
	chef-cli validate-data -m metadata.json -r comment < comment.json
	chef-cli validate-data -m metadata.json -r user < user.json
	chef-cli validate-data -m metadata.json -r incident < incident.json
	echo "data problems checked" > $@

issues-schema.json: metadata-problems
	chef-cli json-schema -r issue < metadata.json > $@

clean:
	rm -f metadata-problems comment.json issue.json user.json incident.json data-problems issues-schema.json
PHONY: clean
