ROOT := ../..

.PHONY: test integration-tests testkit-integration-tests clean

test: testkit-integration-tests

testkit-integration-tests:
	@sh trigger_testkit.sh dephy_repo_golden_sample_integration \
	    $(MAKE) -C $(CURDIR) integration-tests

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
	@echo ""
	@echo "--- audit_product_structure ---"
	@sh ../../scripts/audit_product_structure.sh ../..

clean:
	rm -rf out
