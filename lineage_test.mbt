///|
test "set_parent creates parent-child relationship" {
  let lineage = LineageTracker::new()
  let result = lineage.set_parent("child1", "parent1")
  assert_true(result is Ok(_))
  assert_eq(lineage.parent("child1"), "parent1")
}

///|
test "set_parent rejects self-parenting" {
  let lineage = LineageTracker::new()
  let result = lineage.set_parent("run1", "run1")
  match result {
    Err(SelfParent(id)) => assert_eq(id, "run1")
    _ => fail("expected SelfParent error")
  }
}

///|
test "set_parent rejects overwriting existing parent" {
  let lineage = LineageTracker::new()
  ignore(lineage.set_parent("child1", "parent1"))
  let result = lineage.set_parent("child1", "parent2")
  match result {
    Err(ParentAlreadySet(id)) => assert_eq(id, "child1")
    _ => fail("expected ParentAlreadySet error")
  }
}

///|
test "set_parent rejects cycles" {
  let lineage = LineageTracker::new()
  ignore(lineage.set_parent("b", "a"))
  ignore(lineage.set_parent("c", "b"))
  let result = lineage.set_parent("a", "c")
  match result {
    Err(LineageCycle(child, parent)) => {
      assert_eq(child, "a")
      assert_eq(parent, "c")
    }
    _ => fail("expected LineageCycle error")
  }
}

///|
test "children returns all children of a parent" {
  let lineage = LineageTracker::new()
  ignore(lineage.set_parent("child1", "parent1"))
  ignore(lineage.set_parent("child2", "parent1"))
  ignore(lineage.set_parent("child3", "parent1"))
  let children = lineage.children("parent1")
  assert_eq(children.length(), 3)
}

///|
test "ancestors returns full ancestor chain" {
  let lineage = LineageTracker::new()
  ignore(lineage.set_parent("d", "c"))
  ignore(lineage.set_parent("c", "b"))
  ignore(lineage.set_parent("b", "a"))
  let ancestors = lineage.ancestors("d")
  assert_eq(ancestors.length(), 3)
  assert_eq(ancestors[0], "c")
  assert_eq(ancestors[1], "b")
  assert_eq(ancestors[2], "a")
}

///|
test "root returns the root ancestor" {
  let lineage = LineageTracker::new()
  ignore(lineage.set_parent("d", "c"))
  ignore(lineage.set_parent("c", "b"))
  ignore(lineage.set_parent("b", "a"))
  assert_eq(lineage.root("d"), "a")
  assert_eq(lineage.root("a"), "a")
}

///|
test "depth returns number of ancestors" {
  let lineage = LineageTracker::new()
  ignore(lineage.set_parent("d", "c"))
  ignore(lineage.set_parent("c", "b"))
  ignore(lineage.set_parent("b", "a"))
  assert_eq(lineage.depth("d"), 3)
  assert_eq(lineage.depth("a"), 0)
}

///|
test "lineage_path returns root to child path" {
  let lineage = LineageTracker::new()
  ignore(lineage.set_parent("d", "c"))
  ignore(lineage.set_parent("c", "b"))
  ignore(lineage.set_parent("b", "a"))
  let path = lineage.lineage_path("d")
  assert_eq(path.length(), 4)
  assert_eq(path[0], "a")
  assert_eq(path[3], "d")
}

///|
test "has_parent and has_children work correctly" {
  let lineage = LineageTracker::new()
  ignore(lineage.set_parent("child1", "parent1"))
  assert_true(lineage.has_parent("child1"))
  assert_true(lineage.has_children("parent1"))
  assert_true(!lineage.has_parent("parent1"))
  assert_true(!lineage.has_children("child1"))
}

///|
test "reparent changes the parent of a run" {
  let lineage = LineageTracker::new()
  ignore(lineage.set_parent("child1", "parent1"))
  let result = lineage.reparent("child1", "parent2")
  assert_true(result is Ok(_))
  assert_eq(lineage.parent("child1"), "parent2")
}

///|
test "remove_parent removes the parent-child relationship" {
  let lineage = LineageTracker::new()
  ignore(lineage.set_parent("child1", "parent1"))
  let result = lineage.remove_parent("child1")
  assert_true(result is Ok(_))
  assert_eq(lineage.parent("child1"), "")
}

///|
test "remove_parent returns error when no parent exists" {
  let lineage = LineageTracker::new()
  let result = lineage.remove_parent("child1")
  match result {
    Err(NoParent(id)) => assert_eq(id, "child1")
    _ => fail("expected NoParent error")
  }
}

///|
test "edge_count returns total number of parent-child edges" {
  let lineage = LineageTracker::new()
  ignore(lineage.set_parent("child1", "parent1"))
  ignore(lineage.set_parent("child2", "parent1"))
  ignore(lineage.set_parent("child3", "parent2"))
  assert_eq(lineage.edge_count(), 3)
}

///|
test "LineageError::message returns readable diagnostics" {
  let err = LineageError::SelfParent("run1")
  let msg = LineageError::message(err)
  assert_true(msg.contains("cannot set self as parent"))
}
