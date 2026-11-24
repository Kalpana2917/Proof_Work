USE proofwork_db;

-- Q1: Show all freelancers (Role based filter)
SELECT * FROM Users WHERE role = 'Freelancer';

-- Q2: Show open projects with organization name (JOIN between Projects and Organizations)
-- Logic: Projects.client_id = Organizations.owner_id (both are user_id of the client)
SELECT P.title, O.org_name, P.budget
FROM Projects P
JOIN Organizations O ON P.client_id = O.owner_id
WHERE P.status = 'Open';

-- Q3: Show freelancer skills (3-Table JOIN - Users to Skills mapping)
SELECT U.full_name, S.skill_name
FROM Users U
JOIN UserSkills US ON U.user_id = US.user_id
JOIN Skills S ON US.skill_id = S.skill_id;

-- Q4: Count applications per freelancer (GROUP BY example)
SELECT user_id, COUNT(*) AS total_applications
FROM Applications
GROUP BY user_id;

-- Q5: UNIQUE constraint proof - Prevents duplicate application for same project
-- This will fail if same user applies twice for same project due to UNIQUE(project_id, user_id)
INSERT INTO Applications VALUES (201, 1, 1, 'Test duplicate application', 80000, 25, 'Pending');

-- Q6: Find project with highest budget (ORDER BY with LIMIT)
SELECT title, budget FROM Projects ORDER BY budget DESC LIMIT 1;

-- Q7: CHECK constraint proof - Rating must be between 1 and 5
-- This will fail due to CHECK constraint on rating
INSERT INTO Reviews VALUES (101, 1, 31, 1, 6.0, 'Test rating', '2026-08-30 11:00:00');

-- Q8: Verified Experience certificates - Final output of ProofWork platform
SELECT U.full_name, P.title AS project, C.certificate_url
FROM Certificates C
JOIN Users U ON C.user_id = U.user_id
JOIN Projects P ON C.project_id = P.project_id;

-- Q9: Total earnings per freelancer (SUM + GROUP BY on Payments)
SELECT A.user_id, SUM(Pay.amount) AS total_earned
FROM Payments Pay
JOIN Applications A ON Pay.application_id = A.application_id
WHERE Pay.payment_status = 'Paid'
GROUP BY A.user_id;

-- Q10: Submission versioning history - Shows version control for work
SELECT A.project_id, A.user_id, S.version, S.status
FROM Submissions S
JOIN Applications A ON S.application_id = A.application_id
ORDER BY S.version DESC;
