DROP VIEW IF EXISTS FreelancerDashboard;
DROP VIEW IF EXISTS VerifiedReport;

CREATE INDEX idx_project_status ON Projects(status);
CREATE INDEX idx_user_role ON Users(role);

CREATE VIEW FreelancerDashboard AS
SELECT U.full_name, P.title, Pay.amount, Pay.payment_status
FROM Users U
JOIN Applications A ON U.user_id = A.freelancer_id
JOIN Payments Pay ON Pay.application_id = A.application_id
JOIN Projects P ON Pay.project_id = P.project_id
WHERE U.role = 'Freelancer';

CREATE VIEW VerifiedReport AS
SELECT U.full_name, O.org_name, P.title, C.certificate_code
FROM Certificates C
JOIN Users U ON C.freelancer_id = U.user_id
JOIN Projects P ON C.project_id = P.project_id
JOIN Organizations O ON O.owner_id = P.client_id;
