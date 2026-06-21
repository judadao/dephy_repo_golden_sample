ROOT := ../..

.PHONY: test integration-tests clean

test: integration-tests

integration-tests:
	@echo ""
	@echo "--- test_repo_layout ---"
	@sh test_repo_layout.sh
	@echo ""
	@echo "--- test_build_scripts ---"
	@sh test_build_scripts.sh
	@echo ""
	@echo "--- test_sync_deps ---"
	@sh test_sync_deps.sh

clean:
	rm -rf out

