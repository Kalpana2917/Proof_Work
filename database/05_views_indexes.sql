USE proofwork_db;

-- ======================================================
-- 05_views_and_reports.sql
-- ProofWork - Views and Reports
-- ======================================================

DROP VIEW IF EXISTS FreelancerDashboard;
DROP VIEW IF EXISTS VerifiedReport;
DROP VIEW IF EXISTS ClientProjectSummary;

-- View 1: Freelancer Dashboard (Payment + Projects)
CREATE VIEW FreelancerDashboard AS
SELECT
    U.user_id,
    U.full_name,
    U.email,
    P.project_id,
    P.title,
    P.category,
    Pay.amount,
    Pay.payment_status AS payment_status,
    Pay.paid_at AS payment_date
FROM Users U
JOIN Applications A ON U.user_id = A.user_id
JOIN Payments Pay ON Pay.application_id = A.application_id
JOIN Projects P ON Pay.project_id = P.project_id
WHERE U.role = 'Freelancer';

-- View 2: Verified Experience Report
CREATE VIEW VerifiedReport AS
SELECT
    U.full_name AS freelancer_name,
    O.org_name,
    O.industry,
    P.title AS project_title,
    P.category,
    C.certificate_url,
    C.issued_at
FROM Certificates C
JOIN Users U ON C.user_id = U.user_id
JOIN Projects P ON C.project_id = P.project_id
JOIN Organizations O ON O.owner_id = P.client_id;

-- View 3: Client Project Summary
CREATE VIEW ClientProjectSummary AS
SELECT
    C.user_id AS client_id,
    C.full_name AS client_name,
    O.org_name,
    COUNT(P.project_id) AS total_projects,
    SUM(P.budget) AS total_budget
FROM Users C
LEFT JOIN Organizations O ON O.owner_id = C.user_id
LEFT JOIN Projects P ON P.client_id = C.user_id
WHERE C.role = 'Client'
GROUP BY C.user_id, C.full_name, O.org_name;

-- Verify Views
SELECT * FROM FreelancerDashboard LIMIT 5;
SELECT * FROM VerifiedReport LIMIT 5;
SELECT * FROM ClientProjectSummary;
