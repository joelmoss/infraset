# Infraset


## Process

### 1. Read the current state
Read the JSON from the state file (if present), and convert into a list of current resources. If the
state file does not exist, an empty one is created.

### 2. Refresh the state
Refresh the state by requesting each resource from its respective provider, and updating the
resource object. Then finally writing the resource set back to the state file.

### 3. Collect resources
Scan the `resource_path` for Ruby files and collect the resources found within them. These collected
resources are then compared with the current resources to determine any changes, removals and/or
additions.

### 4. Compile resources
Resources with dynamic attributes are compiled, which produces a final list of static resources, and
defined attributes.

### 5. Build the Plan
Produce and output an execution plan of changed resources.

### 5. Execute the plan

### 6. Save the successful plan as the current state
