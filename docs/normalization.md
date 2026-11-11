# Normalization - ProofWork Database

## 1NF - First Normal Form
- All tables have atomic values, no repeating groups or arrays.
- Example: 
    - `Users.email` has single email per user.
    - `UserSkills` uses separate rows for each skill instead of comma-separated list.
    - `Skills` table separated to avoid multi-valued attribute.

## 2NF - Second Normal Form
- Already in 1NF.
- All non-key attributes fully dependent on entire Primary Key (no partial dependency).
- Example:
    - `Projects` (project_id PK): title, description, budget, category fully dependent on project_id.
    - `UserSkills` (user_id, skill_id Composite PK): proficiency_level, experience_years dependent on full composite key, not just user_id.
    - `Applications` (project_id, user_id UNIQUE): status depends on full combination.

## 3NF - Third Normal Form
- Already in 2NF.
- No transitive dependency (non-key attribute should not depend on another non-key).
- Example:
    - Instead of storing skill_name directly in Users table (which would cause transitive: user_id -> skill_id -> skill_name), we separated:
        - `Skills(skill_id, skill_name)` - Master table
        - `UserSkills(user_id, skill_id, proficiency_level)` - Mapping table
    - `Organizations`: org_name does not depend on user email, only on org_id. Owner details kept in Users table.
    - `Projects`: client_id (user_id) stored, client details not duplicated - fetched via JOIN.

## BCNF - Boyce-Codd Normal Form
- All determinants are candidate keys / superkeys.
- Example:
    - `Skills.skill_name` is UNIQUE, so determinant skill_name is a candidate key.
    - `Users.email` is UNIQUE.
    - Design satisfies BCNF as every functional dependency has superkey on LHS.

## Constraints Used (Professional Implementation)

- **PRIMARY KEY:** On all tables - `Users(user_id)`, `Projects(project_id)`, `Skills(skill_id)`, `Organizations(org_id)`, Composite PK on `UserSkills(user_id, skill_id)`
- **FOREIGN KEY:**
    - `Organizations.owner_id -> Users.user_id`
    - `Projects.client_id -> Users.user_id` (ProofWork logic: Client is a User)
    - `UserSkills.user_id -> Users.user_id`
    - `UserSkills.skill_id -> Skills.skill_id`
    - `Applications.project_id -> Projects.project_id`
    - `Transactions.project_id -> Projects.project_id`
- **UNIQUE:**
    - `UNIQUE(email)` in Users
    - `UNIQUE(skill_name)` in Skills
    - `UNIQUE(project_id, user_id)` in Applications - Prevents duplicate application (Q5)
    - `UNIQUE(project_id)` in VerifiedExperience - One certificate per project
- **CHECK:**
    - `CHECK (budget BETWEEN 5000 AND 200000)` in Projects
    - `CHECK (experience_years BETWEEN 1 AND 5)` in UserSkills
    - `CHECK (rating BETWEEN 1 AND 5)` in Reviews (Q7)
- **ENUM:** `proficiency_level ENUM('Beginner','Intermediate','Expert')`
- **DEFAULT & TIMESTAMP:** `submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP`, `NOW()` via Trigger# Normalization - ProofWork Database

## 1NF - First Normal Form
All tables have atomic values. No repeating groups.
Example: Users table has single value for email, full_name.

## 2NF - Second Normal Form
- Already in 1NF
- All non-key attributes fully dependent on Primary Key.
- Example: In Projects, budget depends only on project_id, not partially.

## 3NF - Third Normal Form
- Already in 2NF
- No transitive dependency.
- Example: Separated Skills and UserSkills tables to avoid transitive dependency of skill_name on user_id.

## BCNF
All determinants are candidate keys. Our design satisfies BCNF.

## Constraints Used (Professional)
- PRIMARY KEY: On all tables
- FOREIGN KEY: Users -> Organizations -> Projects chain
- UNIQUE: UNIQUE(project_id, user_id) in Applications table
- CHECK: rating BETWEEN 1 AND 5 in Reviews table
