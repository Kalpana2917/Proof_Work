DROP VIEW IF EXISTS FreelancerDashboard;
DROP VIEW IF EXISTS VerifiedReport;

--view1
CREATE VIEW FreelancerDashboard AS
SELECT U.full_name, P.title, T.amount, T.status as payment_status
FROM Users U
JOIN Applications A ON U.user_id = A.user_id
JOIN Transactions T ON T.project_id = A.project_id AND T.user_id = A.user_id
JOIN Projects P ON T.project_id = P.project_id
WHERE U.role = 'Freelancer';

--view2
CREATE VIEW VerifiedReport AS
SELECT U.full_name, O.org_name, P.title, V.certificate_url
FROM VerifiedExperience V
JOIN Users U ON V.user_id = U.user_id
JOIN Projects P ON V.project_id = P.project_id
JOIN Organizations O ON O.owner_id = P.client_id;
