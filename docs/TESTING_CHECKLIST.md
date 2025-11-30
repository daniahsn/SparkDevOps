# DevOps Testing Checklist

This document outlines comprehensive testing scenarios for the Spark DevOps infrastructure.

## ✅ Completed Tests

- [x] CI/CD pipeline runs on PR
- [x] All 4 jobs execute (lint, test, build, docker-compose)
- [x] Jobs run in correct dependency order
- [x] No merge conflicts

## 🔍 Additional Tests to Perform

### 1. Test Branch Protection (If Enabled)

**Test: Direct push to main should be blocked**
```bash
# Try to push directly to main (should fail if protection is enabled)
git checkout main
echo "# Test" >> TEST.md
git add TEST.md
git commit -m "Test direct push"
git push origin main
# Expected: Should be rejected/blocked
```

**Test: PR merge requires CI to pass**
- Create a PR with failing tests
- Verify it cannot be merged until CI passes

### 2. Test Failing CI Scenarios

**Test A: Failing Lint**
```bash
# Create a branch with linting errors
git checkout -b test/failing-lint
# Add a file with bad Python style
echo "import os, sys  # Bad: multiple imports" >> backend/test_lint.py
git add backend/test_lint.py
git commit -m "Add linting error"
git push origin test/failing-lint
# Create PR - lint should fail
```

**Test B: Failing Tests**
```bash
# Create a branch with a failing test
git checkout -b test/failing-tests
# Modify test_app.py to add a failing test
# Or break existing functionality
git commit -m "Add failing test"
git push origin test/failing-tests
# Create PR - tests should fail
```

**Test C: Failing Docker Build**
```bash
# Create a branch with broken Dockerfile
git checkout -b test/failing-docker
# Break the Dockerfile (e.g., wrong base image)
git commit -m "Break Dockerfile"
git push origin test/failing-docker
# Create PR - build should fail
```

### 3. Test Local Development Workflow

**Test Makefile Commands:**
```bash
make help          # Should show all commands
make build         # Should build Docker image
make up            # Should start services
make health        # Should return healthy status
make test          # Should run all tests
make lint          # Should run linting
make logs          # Should show container logs
make down          # Should stop services
make clean         # Should clean up everything
```

**Test API Endpoints Locally:**
```bash
# Start services
make up

# Test health endpoint
curl http://localhost:5001/health

# Test creating an entry
curl -X POST http://localhost:5001/api/entries \
  -H "Content-Type: application/json" \
  -d '{"title":"Test","content":"Test content"}'

# Test getting entries
curl http://localhost:5001/api/entries

# Test updating an entry (use ID from previous response)
curl -X PUT http://localhost:5001/api/entries/<ID> \
  -H "Content-Type: application/json" \
  -d '{"title":"Updated","content":"Updated content"}'

# Test deleting an entry
curl -X DELETE http://localhost:5001/api/entries/<ID>
```

### 4. Test Docker Compose Locally

**Test Full Stack:**
```bash
# Build and start
docker-compose build
docker-compose up -d

# Check logs
docker-compose logs backend

# Test health
curl http://localhost:5001/health

# Stop and clean
docker-compose down
```

**Test Data Persistence:**
```bash
# Start services, create data
make up
curl -X POST http://localhost:5001/api/entries \
  -H "Content-Type: application/json" \
  -d '{"title":"Persist Test","content":"Should persist"}'

# Stop services
make down

# Restart and verify data persists
make up
curl http://localhost:5001/api/entries
# Should see the entry we created
```

### 5. Test Error Handling

**Test Invalid API Requests:**
```bash
# Missing required fields
curl -X POST http://localhost:5001/api/entries \
  -H "Content-Type: application/json" \
  -d '{"content":"Missing title"}'
# Should return 400

# Invalid entry ID
curl http://localhost:5001/api/entries/invalid-id
# Should return 404

# Update non-existent entry
curl -X PUT http://localhost:5001/api/entries/nonexistent \
  -H "Content-Type: application/json" \
  -d '{"title":"Test"}'
# Should return 404
```

### 6. Test CI/CD Edge Cases

**Test: Multiple PRs Simultaneously**
- Create 2 PRs at the same time
- Verify both run CI independently
- Verify no conflicts

**Test: PR with Merge Conflicts**
- Create a branch that conflicts with main
- Verify GitHub shows conflict warning
- Resolve and verify CI still runs

**Test: Large PR**
- Create a PR with many changes
- Verify CI handles it correctly
- Check that all jobs complete

### 7. Test Documentation

**Verify:**
- [ ] README.md has all necessary information
- [ ] Backend README explains API endpoints
- [ ] Branch protection guide is accurate
- [ ] All commands in Makefile are documented

### 8. Test Reproducibility

**Test: Fresh Clone Works**
```bash
# In a new directory
git clone <repo-url>
cd SparkDevOps
make build
make up
make test
# Everything should work without additional setup
```

### 9. Test Performance

**Test:**
- CI pipeline completes in reasonable time (< 5 minutes)
- Docker builds are cached properly
- Tests run quickly (< 30 seconds)

### 10. Test Security

**Test:**
- [ ] No secrets in code
- [ ] .gitignore excludes sensitive files
- [ ] Docker image doesn't expose unnecessary ports
- [ ] API has basic input validation

## Quick Test Script

Run this to test the most critical paths:

```bash
#!/bin/bash
echo "Testing DevOps Infrastructure..."

# Test local build
echo "1. Testing local build..."
make build || exit 1

# Test services start
echo "2. Testing services..."
make up || exit 1
sleep 5

# Test health
echo "3. Testing health endpoint..."
curl -f http://localhost:5001/health || exit 1

# Test API
echo "4. Testing API..."
ENTRY_ID=$(curl -s -X POST http://localhost:5001/api/entries \
  -H "Content-Type: application/json" \
  -d '{"title":"Test","content":"Test"}' | grep -o '"id":"[^"]*' | cut -d'"' -f4)
curl -f http://localhost:5001/api/entries/$ENTRY_ID || exit 1

# Test cleanup
echo "5. Testing cleanup..."
make down || exit 1

echo "✅ All tests passed!"
```

## Success Criteria

All tests should:
- ✅ Complete without errors
- ✅ Return expected results
- ✅ Follow the documented workflow
- ✅ Maintain data integrity
- ✅ Provide clear error messages

## Reporting Issues

If any test fails:
1. Document the failure
2. Check CI logs for details
3. Verify local environment matches CI
4. Create an issue or fix the problem
5. Re-run the test

