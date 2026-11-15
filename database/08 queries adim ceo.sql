/*
===============================================================================
PROJECT : PROOFWORK - VERIFIED FREELANCER LEDGER
FILE    : 08_queries_admin_ceo_40.sql
ROLE    : Member 6 - Business Analyst II (Admin & CEO Analytics)
DBMS    : MySQL 8.0+
PURPOSE : 40 management, ranking, trend, KPI and risk-monitoring queries

SCHEMA BASIS:
- Users, Organizations, Projects
- Skills, UserSkills
- Applications, Milestones, Submissions
- Verifications, Reviews, Payments, Certificates

IMPORTANT:
1. This file targets the UPDATED team structure:
   Payments (not Transactions), Certificates (not VerifiedExperience),
   and Verifications.
2. Applications contains application_id, project_id, user_id, proposal_text,
   bid_amount, estimated_days, status.
3. Submissions contains submission_id, application_id, version, file_url,
   submission_notes, submitted_at, status.
4. Payments contains payment_id, project_id, milestone_id, application_id,
   amount, payment_method, payment_status, paid_at.
5. UserSkills connects Users and Skills.
6. MySQL 8.0+ is required for CTEs and window functions.
7. Queries are read-only SELECT statements. They do not modify records.

Run after the team has created and populated the final tables:
USE proofwork_db;
===============================================================================
*/

USE proofwork_db;


/*=============================================================================
 PART A - RANKING & LEADERBOARD ANALYTICS (Q1-Q10)
 Required concepts: RANK(), DENSE_RANK(), ROW_NUMBER()
=============================================================================*/


-- Q1. TOP 5 FREELANCERS BY SUCCESSFUL PAYMENT EARNINGS
-- Business Insight: Identifies the freelancers generating the highest paid
-- value, helping the CEO recognise high-value contributors.
SELECT
    u.user_id,
    u.full_name,
    SUM(p.amount) AS total_earnings,
    RANK() OVER (ORDER BY SUM(p.amount) DESC) AS earnings_rank
FROM Users u
JOIN Applications a ON a.user_id = u.user_id
JOIN Payments p ON p.application_id = a.application_id
WHERE u.role = 'Freelancer'
  AND p.payment_status = 'Paid'
GROUP BY u.user_id, u.full_name
ORDER BY total_earnings DESC
LIMIT 5;


-- Q2. RANK PROJECTS BY TOTAL SUCCESSFUL PAYMENT VALUE
-- Business Insight: Shows which projects account for the greatest realised
-- payment value, rather than relying only on their proposed budgets.
SELECT
    pr.project_id,
    pr.title,
    SUM(p.amount) AS total_paid,
    RANK() OVER (ORDER BY SUM(p.amount) DESC) AS project_payment_rank
FROM Projects pr
JOIN Payments p ON p.project_id = pr.project_id
WHERE p.payment_status = 'Paid'
GROUP BY pr.project_id, pr.title
ORDER BY total_paid DESC;


-- Q3. TOP 10 FREELANCERS BY AVERAGE CLIENT RATING
-- Business Insight: Highlights consistently well-reviewed freelancers
-- and supports quality-based recognition.
SELECT
    u.user_id,
    u.full_name,
    ROUND(AVG(r.rating), 2) AS average_rating,
    COUNT(r.review_id) AS total_reviews,
    DENSE_RANK() OVER (ORDER BY AVG(r.rating) DESC) AS rating_rank
FROM Users u
JOIN Reviews r ON r.reviewee_id = u.user_id
WHERE u.role = 'Freelancer'
GROUP BY u.user_id, u.full_name
ORDER BY average_rating DESC, total_reviews DESC
LIMIT 10;


-- Q4. SECOND-HIGHEST PROJECT BUDGET (INCLUDING TIES)
-- Business Insight: Identifies the project or projects at the second-highest
-- distinct budget level for management review.
WITH ProjectBudgetRanks AS (
    SELECT
        project_id,
        title,
        budget,
        DENSE_RANK() OVER (ORDER BY budget DESC) AS budget_rank
    FROM Projects
)
SELECT project_id, title, budget
FROM ProjectBudgetRanks
WHERE budget_rank = 2;


-- Q5. RANK ORGANIZATIONS BY NUMBER OF COMPLETED PROJECTS
-- Business Insight: Shows which client organizations have completed the
-- largest number of projects on the platform.
SELECT
    o.org_id,
    o.org_name,
    COUNT(pr.project_id) AS completed_projects,
    RANK() OVER (ORDER BY COUNT(pr.project_id) DESC) AS organization_rank
FROM Organizations o
JOIN Projects pr ON pr.client_id = o.owner_id
WHERE pr.status = 'Completed'
GROUP BY o.org_id, o.org_name
ORDER BY completed_projects DESC;


-- Q6. RANK FREELANCERS BY TRUST SCORE
-- Business Insight: Gives administrators a trust-score leaderboard for
-- monitoring freelancer reputation on the platform.
SELECT
    user_id,
    full_name,
    trust_score,
    DENSE_RANK() OVER (ORDER BY trust_score DESC) AS trust_rank
FROM Users
WHERE role = 'Freelancer'
ORDER BY trust_score DESC;


-- Q7. RANK CITIES BY SUCCESSFUL PAYMENT VALUE EARNED BY FREELANCERS
-- Business Insight: Reveals the locations contributing the highest
-- freelancer payment value.
SELECT
    u.city,
    SUM(p.amount) AS total_freelancer_earnings,
    RANK() OVER (ORDER BY SUM(p.amount) DESC) AS city_rank
FROM Users u
JOIN Applications a ON a.user_id = u.user_id
JOIN Payments p ON p.application_id = a.application_id
WHERE u.role = 'Freelancer'
  AND p.payment_status = 'Paid'
GROUP BY u.city
ORDER BY total_freelancer_earnings DESC;


-- Q8. LATEST SUBMISSION FOR EACH APPLICATION
-- Business Insight: Lets operations staff see the most recent work version
-- submitted for every application without manually checking all versions.
WITH NumberedSubmissions AS (
    SELECT
        s.submission_id,
        s.application_id,
        s.version,
        s.status,
        s.submitted_at,
        ROW_NUMBER() OVER (
            PARTITION BY s.application_id
            ORDER BY s.submitted_at DESC, s.submission_id DESC
        ) AS submission_row
    FROM Submissions s
)
SELECT
    submission_id,
    application_id,
    version,
    status,
    submitted_at
FROM NumberedSubmissions
WHERE submission_row = 1
ORDER BY submitted_at DESC;


-- Q9. RANK FREELANCER BIDS WITHIN EACH PROJECT
-- Business Insight: Helps clients compare bids for the same project and
-- identify the lowest offered bid in each project.
SELECT
    a.project_id,
    a.application_id,
    u.full_name AS freelancer_name,
    a.bid_amount,
    RANK() OVER (
        PARTITION BY a.project_id
        ORDER BY a.bid_amount ASC
    ) AS bid_rank_in_project
FROM Applications a
JOIN Users u ON u.user_id = a.user_id
ORDER BY a.project_id, bid_rank_in_project;


-- Q10. TOP 10 ORGANIZATIONS BY TOTAL PROJECT BUDGET
-- Business Insight: Identifies the client organizations managing the
-- largest total project budgets on ProofWork.
SELECT
    o.org_id,
    o.org_name,
    SUM(pr.budget) AS total_project_budget,
    ROW_NUMBER() OVER (ORDER BY SUM(pr.budget) DESC, o.org_id) AS budget_position
FROM Organizations o
JOIN Projects pr ON pr.client_id = o.owner_id
GROUP BY o.org_id, o.org_name
ORDER BY total_project_budget DESC
LIMIT 10;


/*=============================================================================
 PART B - CTEs & TIME-SERIES ANALYTICS (Q11-Q20)
 Required concepts: WITH, LAG(), LEAD(), PARTITION BY, running totals
=============================================================================*/


-- Q11. MONTH-ON-MONTH SUCCESSFUL PAYMENT TOTALS
-- Business Insight: Gives the CEO a monthly view of realised payment volume.
WITH MonthlyPayments AS (
    SELECT
        DATE_FORMAT(paid_at, '%Y-%m') AS payment_month,
        SUM(amount) AS monthly_paid_amount
    FROM Payments
    WHERE payment_status = 'Paid'
      AND paid_at IS NOT NULL
    GROUP BY DATE_FORMAT(paid_at, '%Y-%m')
)
SELECT payment_month, monthly_paid_amount
FROM MonthlyPayments
ORDER BY payment_month;


-- Q12. MONTH-ON-MONTH PAYMENT GROWTH USING LAG()
-- Business Insight: Shows whether successful payment value increased or
-- decreased compared with the previous month.
WITH MonthlyPayments AS (
    SELECT
        DATE_FORMAT(paid_at, '%Y-%m') AS payment_month,
        SUM(amount) AS monthly_paid_amount
    FROM Payments
    WHERE payment_status = 'Paid'
      AND paid_at IS NOT NULL
    GROUP BY DATE_FORMAT(paid_at, '%Y-%m')
),
PaymentComparison AS (
    SELECT
        payment_month,
        monthly_paid_amount,
        LAG(monthly_paid_amount) OVER (ORDER BY payment_month) AS previous_month_amount
    FROM MonthlyPayments
)
SELECT
    payment_month,
    monthly_paid_amount,
    previous_month_amount,
    monthly_paid_amount - previous_month_amount AS amount_change,
    ROUND(
        100.0 * (monthly_paid_amount - previous_month_amount)
        / NULLIF(previous_month_amount, 0), 2
    ) AS growth_percentage
FROM PaymentComparison
ORDER BY payment_month;


-- Q13. NEXT MONTH PAYMENT VALUE USING LEAD()
-- Business Insight: Allows management to compare each month's payment
-- value with the next recorded month in the available data.
WITH MonthlyPayments AS (
    SELECT
        DATE_FORMAT(paid_at, '%Y-%m') AS payment_month,
        SUM(amount) AS monthly_paid_amount
    FROM Payments
    WHERE payment_status = 'Paid'
      AND paid_at IS NOT NULL
    GROUP BY DATE_FORMAT(paid_at, '%Y-%m')
)
SELECT
    payment_month,
    monthly_paid_amount,
    LEAD(monthly_paid_amount) OVER (ORDER BY payment_month) AS next_month_amount
FROM MonthlyPayments
ORDER BY payment_month;


-- Q14. RUNNING TOTAL OF SUCCESSFUL PAYMENTS BY DATE
-- Business Insight: Tracks cumulative successful payment value over time.
WITH DailyPayments AS (
    SELECT
        DATE(paid_at) AS payment_date,
        SUM(amount) AS daily_paid_amount
    FROM Payments
    WHERE payment_status = 'Paid'
      AND paid_at IS NOT NULL
    GROUP BY DATE(paid_at)
)
SELECT
    payment_date,
    daily_paid_amount,
    SUM(daily_paid_amount) OVER (
        ORDER BY payment_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_paid_total
FROM DailyPayments
ORDER BY payment_date;


-- Q15. MONTHLY EARNINGS AND MONTHLY RANK OF EACH FREELANCER
-- Business Insight: Compares freelancer earnings within each month and
-- helps identify the strongest monthly contributors.
WITH FreelancerMonthlyEarnings AS (
    SELECT
        DATE_FORMAT(p.paid_at, '%Y-%m') AS payment_month,
        u.user_id,
        u.full_name,
        SUM(p.amount) AS monthly_earnings
    FROM Payments p
    JOIN Applications a ON a.application_id = p.application_id
    JOIN Users u ON u.user_id = a.user_id
    WHERE p.payment_status = 'Paid'
      AND p.paid_at IS NOT NULL
      AND u.role = 'Freelancer'
    GROUP BY DATE_FORMAT(p.paid_at, '%Y-%m'), u.user_id, u.full_name
)
SELECT
    payment_month,
    user_id,
    full_name,
    monthly_earnings,
    DENSE_RANK() OVER (
        PARTITION BY payment_month
        ORDER BY monthly_earnings DESC
    ) AS monthly_earning_rank
FROM FreelancerMonthlyEarnings
ORDER BY payment_month, monthly_earning_rank;


-- Q16. MONTHLY NEW USER REGISTRATIONS AND RUNNING REGISTRATION TOTAL
-- Business Insight: Helps the CEO monitor platform adoption and cumulative
-- user growth over time.
WITH MonthlyRegistrations AS (
    SELECT
        DATE_FORMAT(created_at, '%Y-%m') AS registration_month,
        COUNT(*) AS new_users
    FROM Users
    GROUP BY DATE_FORMAT(created_at, '%Y-%m')
)
SELECT
    registration_month,
    new_users,
    SUM(new_users) OVER (
        ORDER BY registration_month
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_users
FROM MonthlyRegistrations
ORDER BY registration_month;


-- Q17. APPLICATION COUNTS AND ACCEPTANCE RATE PER PROJECT
-- Business Insight: Identifies projects attracting applicants and measures
-- how many applications have been accepted for each project.
WITH ProjectApplicationStats AS (
    SELECT
        project_id,
        COUNT(*) AS total_applications,
        SUM(CASE WHEN status = 'Accepted' THEN 1 ELSE 0 END) AS accepted_applications
    FROM Applications
    GROUP BY project_id
)
SELECT
    pr.project_id,
    pr.title,
    COALESCE(s.total_applications, 0) AS total_applications,
    COALESCE(s.accepted_applications, 0) AS accepted_applications,
    ROUND(
        100.0 * COALESCE(s.accepted_applications, 0)
        / NULLIF(s.total_applications, 0), 2
    ) AS acceptance_percentage
FROM Projects pr
LEFT JOIN ProjectApplicationStats s ON s.project_id = pr.project_id
ORDER BY acceptance_percentage DESC;


-- Q18. AVERAGE TIME BETWEEN SUBMISSION AND VERIFICATION
-- Business Insight: Measures verification turnaround time and helps
-- operations identify delays in reviewing submitted work.
WITH VerificationTimes AS (
    SELECT
        s.submission_id,
        s.submitted_at,
        v.verified_at,
        TIMESTAMPDIFF(HOUR, s.submitted_at, v.verified_at) AS hours_to_verify
    FROM Submissions s
    JOIN Verifications v ON v.submission_id = s.submission_id
    WHERE v.verified_at >= s.submitted_at
)
SELECT
    COUNT(*) AS verified_submission_count,
    ROUND(AVG(hours_to_verify), 2) AS average_verification_hours,
    MAX(hours_to_verify) AS maximum_verification_hours
FROM VerificationTimes;


-- Q19. MONTHLY PAYMENT TOTALS BY PAYMENT METHOD
-- Business Insight: Shows which payment channels are being used and how
-- successful payment value changes across months.
WITH MethodMonthlyTotals AS (
    SELECT
        DATE_FORMAT(paid_at, '%Y-%m') AS payment_month,
        payment_method,
        SUM(amount) AS method_total
    FROM Payments
    WHERE payment_status = 'Paid'
      AND paid_at IS NOT NULL
    GROUP BY DATE_FORMAT(paid_at, '%Y-%m'), payment_method
)
SELECT
    payment_month,
    payment_method,
    method_total,
    SUM(method_total) OVER (
        PARTITION BY payment_method
        ORDER BY payment_month
    ) AS method_running_total
FROM MethodMonthlyTotals
ORDER BY payment_month, payment_method;


-- Q20. MONTHLY REALISED PAYMENT VALUE BY PROJECT CATEGORY
-- Business Insight: Helps management understand which project categories
-- contribute successful payment value over time.
WITH CategoryMonthlyPayments AS (
    SELECT
        DATE_FORMAT(p.paid_at, '%Y-%m') AS payment_month,
        pr.category,
        SUM(p.amount) AS paid_amount
    FROM Payments p
    JOIN Projects pr ON pr.project_id = p.project_id
    WHERE p.payment_status = 'Paid'
      AND p.paid_at IS NOT NULL
    GROUP BY DATE_FORMAT(p.paid_at, '%Y-%m'), pr.category
)
SELECT
    payment_month,
    category,
    paid_amount,
    RANK() OVER (
        PARTITION BY payment_month
        ORDER BY paid_amount DESC
    ) AS category_rank_for_month
FROM CategoryMonthlyPayments
ORDER BY payment_month, category_rank_for_month;


/*=============================================================================
 PART C - BUSINESS KPIs & AGGREGATION (Q21-Q30)
 Required concepts: GROUP BY, HAVING, CASE
=============================================================================*/


-- Q21. PROJECT CATEGORIES WITH TOTAL BUDGET ABOVE 200,000
-- Business Insight: Highlights categories with substantial planned
-- investment and helps management understand budget concentration.
SELECT
    category,
    COUNT(*) AS project_count,
    SUM(budget) AS total_budget,
    ROUND(AVG(budget), 2) AS average_budget
FROM Projects
GROUP BY category
HAVING SUM(budget) > 200000
ORDER BY total_budget DESC;


-- Q22. SKILLS ASSOCIATED WITH THE HIGHEST SUCCESSFUL PAYMENT VALUE
-- Business Insight: Shows which freelancer skills are associated with
-- higher paid project value for talent-marketplace planning.
-- Note: A freelancer may have multiple skills, so the same payment can be
-- attributed to more than one skill. Skill totals are not additive.
SELECT
    s.skill_id,
    s.skill_name,
    COUNT(DISTINCT p.payment_id) AS paid_payment_count,
    SUM(p.amount) AS attributed_paid_amount
FROM Skills s
JOIN UserSkills us ON us.skill_id = s.skill_id
JOIN Applications a ON a.user_id = us.user_id
JOIN Payments p ON p.application_id = a.application_id
WHERE p.payment_status = 'Paid'
GROUP BY s.skill_id, s.skill_name
HAVING COUNT(DISTINCT p.payment_id) >= 1
ORDER BY attributed_paid_amount DESC
LIMIT 10;


-- Q23. CITIES WITH THE HIGHEST NUMBER OF FREELANCERS
-- Business Insight: Identifies freelancer concentration by city and
-- supports location-based platform outreach.
SELECT
    city,
    COUNT(*) AS freelancer_count,
    CASE
        WHEN COUNT(*) >= 10 THEN 'High Freelancer Presence'
        WHEN COUNT(*) >= 5 THEN 'Moderate Freelancer Presence'
        ELSE 'Emerging Freelancer Presence'
    END AS city_segment
FROM Users
WHERE role = 'Freelancer'
GROUP BY city
HAVING COUNT(*) >= 1
ORDER BY freelancer_count DESC;


-- Q24. ORGANIZATIONS WITH MORE THAN TWO PROJECTS
-- Business Insight: Identifies active client organizations that repeatedly
-- use ProofWork to publish projects.
SELECT
    o.org_id,
    o.org_name,
    COUNT(pr.project_id) AS total_projects,
    SUM(pr.budget) AS combined_project_budget
FROM Organizations o
JOIN Projects pr ON pr.client_id = o.owner_id
GROUP BY o.org_id, o.org_name
HAVING COUNT(pr.project_id) > 2
ORDER BY total_projects DESC;


-- Q25. FREELANCERS CLASSIFIED BY TRUST SCORE
-- Business Insight: Gives administrators a simple trust segmentation
-- for monitoring freelancer reputation.
SELECT
    CASE
        WHEN trust_score >= 80 THEN 'High Trust'
        WHEN trust_score >= 50 THEN 'Medium Trust'
        ELSE 'Needs Monitoring'
    END AS trust_category,
    COUNT(*) AS freelancer_count,
    ROUND(AVG(trust_score), 2) AS average_trust_score
FROM Users
WHERE role = 'Freelancer'
GROUP BY
    CASE
        WHEN trust_score >= 80 THEN 'High Trust'
        WHEN trust_score >= 50 THEN 'Medium Trust'
        ELSE 'Needs Monitoring'
    END
ORDER BY average_trust_score DESC;


-- Q26. PROJECT STATUS DISTRIBUTION
-- Business Insight: Shows the balance of Open, In Progress and Completed
-- projects, helping the CEO understand platform workload.
SELECT
    status,
    COUNT(*) AS project_count,
    SUM(budget) AS total_budget,
    CASE
        WHEN status = 'Completed' THEN 'Delivered'
        WHEN status = 'In Progress' THEN 'Active Work'
        WHEN status = 'Open' THEN 'Awaiting Freelancer'
        ELSE 'Other Status'
    END AS management_group
FROM Projects
GROUP BY status
ORDER BY project_count DESC;


-- Q27. FREELANCERS WITH AVERAGE RATING OF AT LEAST 4.5
-- Business Insight: Finds highly rated freelancers with enough review
-- activity to be useful for quality and recognition programmes.
SELECT
    u.user_id,
    u.full_name,
    COUNT(r.review_id) AS review_count,
    ROUND(AVG(r.rating), 2) AS average_rating,
    CASE
        WHEN AVG(r.rating) >= 4.8 THEN 'Excellent'
        WHEN AVG(r.rating) >= 4.5 THEN 'Strong'
        ELSE 'Good'
    END AS rating_category
FROM Users u
JOIN Reviews r ON r.reviewee_id = u.user_id
WHERE u.role = 'Freelancer'
GROUP BY u.user_id, u.full_name
HAVING COUNT(r.review_id) >= 2
   AND AVG(r.rating) >= 4.5
ORDER BY average_rating DESC, review_count DESC;


-- Q28. PAYMENT METHOD PERFORMANCE
-- Business Insight: Compares paid, pending and failed payment counts for
-- each payment method to help finance teams monitor payment operations.
SELECT
    payment_method,
    COUNT(*) AS total_payment_attempts,
    SUM(CASE WHEN payment_status = 'Paid' THEN 1 ELSE 0 END) AS paid_count,
    SUM(CASE WHEN payment_status = 'Pending' THEN 1 ELSE 0 END) AS pending_count,
    SUM(CASE WHEN payment_status = 'Failed' THEN 1 ELSE 0 END) AS failed_count,
    SUM(CASE WHEN payment_status = 'Paid' THEN amount ELSE 0 END) AS successful_value
FROM Payments
GROUP BY payment_method
HAVING COUNT(*) > 0
ORDER BY successful_value DESC;


-- Q29. CLIENTS WITH AT LEAST FIVE APPLICATIONS ACROSS THEIR PROJECTS
-- Business Insight: Identifies clients whose projects attract substantial
-- freelancer interest across the platform.
SELECT
    u.user_id AS client_user_id,
    u.full_name AS client_name,
    COUNT(a.application_id) AS applications_received,
    COUNT(DISTINCT pr.project_id) AS projects_posted,
    CASE
        WHEN COUNT(a.application_id) >= 20 THEN 'Very High Interest'
        WHEN COUNT(a.application_id) >= 10 THEN 'High Interest'
        ELSE 'Growing Interest'
    END AS interest_level
FROM Users u
JOIN Projects pr ON pr.client_id = u.user_id
JOIN Applications a ON a.project_id = pr.project_id
WHERE u.role = 'Client'
GROUP BY u.user_id, u.full_name
HAVING COUNT(a.application_id) >= 5
ORDER BY applications_received DESC;


-- Q30. OVERDUE MILESTONES BY PROJECT
-- Business Insight: Gives operations staff a list of projects with
-- milestones marked overdue or still pending past their due date.
SELECT
    pr.project_id,
    pr.title,
    COUNT(m.milestone_id) AS overdue_milestones,
    SUM(m.amount) AS value_of_overdue_milestones,
    CASE
        WHEN COUNT(m.milestone_id) >= 3 THEN 'Critical Attention'
        WHEN COUNT(m.milestone_id) = 2 THEN 'High Attention'
        ELSE 'Monitor'
    END AS attention_level
FROM Projects pr
JOIN Milestones m ON m.project_id = pr.project_id
WHERE m.status = 'Overdue'
   OR (m.status = 'Pending' AND m.due_date < CURDATE())
GROUP BY pr.project_id, pr.title
HAVING COUNT(m.milestone_id) > 0
ORDER BY overdue_milestones DESC, value_of_overdue_milestones DESC;


/*=============================================================================
 PART D - RISK, EXCEPTION & FRAUD-INDICATOR ANALYTICS (Q31-Q40)
 Required concepts: EXISTS, NOT EXISTS, subqueries
NOTE: These queries flag records for human review. They do not prove fraud.
=============================================================================*/


-- Q31. FAILED PAYMENTS ABOVE 100,000
-- Business Insight: Flags unusually large failed payment attempts for
-- finance-team investigation and payment-gateway follow-up.
SELECT
    payment_id,
    project_id,
    application_id,
    amount,
    payment_method,
    payment_status,
    paid_at
FROM Payments
WHERE payment_status = 'Failed'
  AND amount > 100000
ORDER BY amount DESC;


-- Q32. PAID APPLICATIONS WITH NO VERIFIED SUBMISSION
-- Business Insight: Flags cases where money is marked Paid but no linked
-- submission has a Verified verification record.
SELECT
    p.payment_id,
    p.project_id,
    p.application_id,
    p.amount,
    p.paid_at
FROM Payments p
WHERE p.payment_status = 'Paid'
  AND NOT EXISTS (
      SELECT 1
      FROM Submissions s
      JOIN Verifications v ON v.submission_id = s.submission_id
      WHERE s.application_id = p.application_id
        AND v.verification_status = 'Verified'
  )
ORDER BY p.amount DESC;


-- Q33. APPLICATIONS WITH THREE OR MORE FAILED PAYMENT ATTEMPTS
-- Business Insight: Detects repeated failed payment attempts associated
-- with the same application for finance-team review.
SELECT
    p.application_id,
    COUNT(*) AS failed_attempts,
    SUM(p.amount) AS total_failed_value
FROM Payments p
WHERE p.payment_status = 'Failed'
GROUP BY p.application_id
HAVING COUNT(*) >= 3
ORDER BY failed_attempts DESC, total_failed_value DESC;


-- Q34. PAID AMOUNT GREATER THAN THE ACCEPTED FREELANCER BID
-- Business Insight: Flags applications where cumulative paid value exceeds
-- the accepted bid amount; legitimate scope changes should be checked too.
SELECT
    a.application_id,
    a.project_id,
    u.full_name AS freelancer_name,
    a.bid_amount,
    SUM(p.amount) AS total_paid_amount,
    SUM(p.amount) - a.bid_amount AS amount_above_bid
FROM Applications a
JOIN Users u ON u.user_id = a.user_id
JOIN Payments p ON p.application_id = a.application_id
WHERE p.payment_status = 'Paid'
  AND a.status = 'Accepted'
GROUP BY a.application_id, a.project_id, u.full_name, a.bid_amount
HAVING SUM(p.amount) > a.bid_amount
ORDER BY amount_above_bid DESC;


-- Q35. CERTIFICATES WHOSE LINKED VERIFICATION IS NOT VERIFIED
-- Business Insight: Finds certificates linked to rejected or under-review
-- verification records so administrators can check certificate validity.
SELECT
    c.certificate_id,
    c.certificate_code,
    c.user_id,
    c.project_id,
    v.verification_status,
    c.issued_at
FROM Certificates c
JOIN Verifications v ON v.verification_id = c.verification_id
WHERE v.verification_status <> 'Verified'
ORDER BY c.issued_at DESC;


-- Q36. ACCEPTED APPLICATIONS WITH NO SUBMISSION
-- Business Insight: Identifies accepted freelancers who have no recorded
-- submission yet, helping operations follow up on stalled work.
SELECT
    a.application_id,
    a.project_id,
    a.user_id,
    u.full_name AS freelancer_name,
    a.estimated_days,
    a.status
FROM Applications a
JOIN Users u ON u.user_id = a.user_id
WHERE a.status = 'Accepted'
  AND NOT EXISTS (
      SELECT 1
      FROM Submissions s
      WHERE s.application_id = a.application_id
  )
ORDER BY a.project_id;


-- Q37. VERIFIED SUBMISSIONS WITH NO SUCCESSFUL PAYMENT
-- Business Insight: Flags verified work for which no successful payment
-- is recorded against the related application.
SELECT
    s.submission_id,
    s.application_id,
    s.version,
    v.verification_status,
    v.verified_at
FROM Submissions s
JOIN Verifications v ON v.submission_id = s.submission_id
WHERE v.verification_status = 'Verified'
  AND NOT EXISTS (
      SELECT 1
      FROM Payments p
      WHERE p.application_id = s.application_id
        AND p.payment_status = 'Paid'
  )
ORDER BY v.verified_at;


-- Q38. PROJECTS WHERE SUCCESSFUL PAYMENTS EXCEED PROJECT BUDGET
-- Business Insight: Flags projects whose cumulative paid amount exceeds
-- the project budget for a financial-control review.
SELECT
    pr.project_id,
    pr.title,
    pr.budget,
    (
        SELECT SUM(p.amount)
        FROM Payments p
        WHERE p.project_id = pr.project_id
          AND p.payment_status = 'Paid'
    ) AS total_paid
FROM Projects pr
WHERE (
    SELECT COALESCE(SUM(p.amount), 0)
    FROM Payments p
    WHERE p.project_id = pr.project_id
      AND p.payment_status = 'Paid'
) > pr.budget
ORDER BY total_paid DESC;


-- Q39. FREELANCERS WITH MULTIPLE CERTIFICATES FOR THE SAME PROJECT
-- Business Insight: Identifies repeated certificate records for the same
-- freelancer-project pair for duplicate-record review.
SELECT
    c.user_id,
    u.full_name,
    c.project_id,
    COUNT(*) AS certificate_count
FROM Certificates c
JOIN Users u ON u.user_id = c.user_id
GROUP BY c.user_id, u.full_name, c.project_id
HAVING COUNT(*) > 1
ORDER BY certificate_count DESC;


-- Q40. VERIFIERS WITH AN UNUSUALLY HIGH REJECTION RATE
-- Business Insight: Highlights verification accounts with a high rejection
-- share for quality-assurance review; a high rate is not proof of misconduct.
SELECT
    v.verifier_id,
    u.full_name AS verifier_name,
    COUNT(*) AS total_verifications,
    SUM(CASE WHEN v.verification_status = 'Rejected' THEN 1 ELSE 0 END) AS rejected_count,
    ROUND(
        100.0 * SUM(CASE WHEN v.verification_status = 'Rejected' THEN 1 ELSE 0 END)
        / COUNT(*), 2
    ) AS rejection_percentage
FROM Verifications v
JOIN Users u ON u.user_id = v.verifier_id
GROUP BY v.verifier_id, u.full_name
HAVING COUNT(*) >= 5
   AND (
       100.0 * SUM(CASE WHEN v.verification_status = 'Rejected' THEN 1 ELSE 0 END)
       / COUNT(*)
   ) >= 50
ORDER BY rejection_percentage DESC, total_verifications DESC;


/*=============================================================================
 END OF MEMBER 6 - 40 CEO & ADMIN ANALYTICS QUERIES
=============================================================================*/
