-- Q1: Show all freelancers (Role based filter)
SELECT * FROM Users WHERE role = 'Freelancer';

-- Q2: Show open projects with organization name (JOIN between Projects and Organizations)
SELECT P.title, O.org_name, P.budget 
FROM Projects P
JOIN Organizations O ON P.org_id = O.org_id
WHERE P.status = 'open';

-- Q3: Show freelancer skills (3-Table JOIN - Users to Skills mapping)
SELECT U.full_name, S.skill_name
FROM Users U
JOIN UserSkills US ON U.user_id = US.user_id
JOIN Skills S ON US.skill_id = S.skill_id;

-- Q4: Count applications per freelancer (GROUP BY example)
SELECT user_id, COUNT(*) as total_applications
FROM Applications
GROUP BY user_id;

-- Q5: UNIQUE constraint proof - Prevents duplicate application for same project
-- INSERT INTO Applications (project_id, user_id) VALUES (1, 1);

-- Q6: Find project with highest budget (ORDER BY with LIMIT)
SELECT title, budget FROM Projects ORDER BY budget DESC LIMIT 1;

-- Q7: CHECK constraint proof - Rating must be between 1 and 5
-- INSERT INTO Reviews (project_id, reviewer_id, rating) VALUES (1, 1, 10);

-- Q8: Verified Experience certificates - Final output of ProofWork platform
SELECT U.full_name, P.title as project, V.certificate_url
FROM VerifiedExperience V
JOIN Users U ON V.user_id = U.user_id
JOIN Projects P ON V.project_id = P.project_id;

-- Q9: Total earnings per freelancer (SUM + GROUP BY on Transactions)
SELECT user_id, SUM(amount) as total_earned 
FROM Transactions 
GROUP BY user_id;

-- Q10: Submission versioning history - Shows version control for work
SELECT project_id, user_id, version_no 
FROM Submissions 
ORDER BY version_no DESC;
