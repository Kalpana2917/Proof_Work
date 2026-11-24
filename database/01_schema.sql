-- ======================================================
-- 01_schema.sql
-- Freelance Project Management System
-- Final Professional - Team Compatible
-- MySQL 8.0+
-- ======================================================
-- ============================================================
-- ProofWork - schema.sql
-- ============================================================

CREATE DATABASE proofwork_db;
USE proofwork_db;

-- 1. Users
CREATE TABLE Users (
  user_id INT PRIMARY KEY,
  full_name VARCHAR(100) NOT NULL,
  email VARCHAR(100) UNIQUE NOT NULL,
  phone VARCHAR(20),
  city VARCHAR(50),
  role ENUM('Freelancer','Client','Admin') NOT NULL,
  linkedin_url VARCHAR(255),
  trust_score DECIMAL(5,2) DEFAULT 0,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 2. Organizations
CREATE TABLE Organizations (
  org_id INT PRIMARY KEY,
  org_name VARCHAR(100) NOT NULL,
  industry VARCHAR(100),
  owner_id INT NOT NULL,
  FOREIGN KEY (owner_id) REFERENCES Users(user_id)
);

-- 3. Projects
CREATE TABLE Projects (
  project_id INT PRIMARY KEY,
  client_id INT NOT NULL,
  title VARCHAR(200) NOT NULL,
  description TEXT,
  category VARCHAR(100),
  budget DECIMAL(10,2) NOT NULL,
  status ENUM('Open','In Progress','Completed') NOT NULL,
  FOREIGN KEY (client_id) REFERENCES Users(user_id)
);

-- 4. Skills
CREATE TABLE Skills (
  skill_id INT PRIMARY KEY,
  skill_name VARCHAR(100) NOT NULL,
  category VARCHAR(100)
);

-- 5. UserSkills
CREATE TABLE UserSkills (
  user_id INT NOT NULL,
  skill_id INT NOT NULL,
  proficiency_level ENUM('Beginner','Intermediate','Expert') NOT NULL,
  experience_years INT,
  PRIMARY KEY (user_id, skill_id),
  FOREIGN KEY (user_id) REFERENCES Users(user_id),
  FOREIGN KEY (skill_id) REFERENCES Skills(skill_id)
);

-- 6. Applications - FINAL 
CREATE TABLE Applications (
  application_id INT PRIMARY KEY,
  project_id INT NOT NULL,
  user_id INT NOT NULL,
  proposal_text TEXT NOT NULL,
  bid_amount DECIMAL(10,2) NOT NULL,
  estimated_days INT NOT NULL,
  status ENUM('Pending','Accepted','Rejected') NOT NULL,
  FOREIGN KEY (project_id) REFERENCES Projects(project_id),
  FOREIGN KEY (user_id) REFERENCES Users(user_id)
);

-- 7. Milestones
CREATE TABLE Milestones (
  milestone_id INT PRIMARY KEY,
  project_id INT NOT NULL,
  title VARCHAR(200) NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  due_date DATE,
  status ENUM('Pending','Completed','Overdue') NOT NULL,
  FOREIGN KEY (project_id) REFERENCES Projects(project_id)
);

-- 8. Submissions 
CREATE TABLE Submissions (
  submission_id INT PRIMARY KEY,
  application_id INT NOT NULL,
  version INT NOT NULL,
  file_url VARCHAR(255),
  submission_notes TEXT,
  submitted_at DATETIME NOT NULL,
  status ENUM('Submitted','Verified','Rejected') NOT NULL,
  FOREIGN KEY (application_id) REFERENCES Applications(application_id)
);

-- 9. Verifications 
CREATE TABLE Verifications (
  verification_id INT PRIMARY KEY,
  submission_id INT NOT NULL,
  verifier_id INT NOT NULL,
  verification_status ENUM('Verified','Rejected','Under Review') NOT NULL,
  verification_notes TEXT,
  verified_at DATETIME NOT NULL,
  FOREIGN KEY (submission_id) REFERENCES Submissions(submission_id),
  FOREIGN KEY (verifier_id) REFERENCES Users(user_id)
);

-- 10. Reviews - CORRECTED 
CREATE TABLE Reviews (
  review_id INT PRIMARY KEY,
  project_id INT NOT NULL,
  reviewer_id INT NOT NULL,
  reviewee_id INT NOT NULL,
  rating DECIMAL(2,1) CHECK (rating >= 1.0 AND rating <= 5.0),
  review_text TEXT,
  created_at DATETIME NOT NULL,
  FOREIGN KEY (project_id) REFERENCES Projects(project_id),
  FOREIGN KEY (reviewer_id) REFERENCES Users(user_id),
  FOREIGN KEY (reviewee_id) REFERENCES Users(user_id)
);

-- 11. Payments - FINAL 
CREATE TABLE Payments (
  payment_id INT PRIMARY KEY,
  project_id INT NOT NULL,
  milestone_id INT NOT NULL,
  application_id INT NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  payment_method ENUM('UPI','Razorpay','Bank Transfer','PayPal') NOT NULL,
  payment_status ENUM('Paid','Pending','Failed') NOT NULL,
  paid_at DATETIME,
  FOREIGN KEY (project_id) REFERENCES Projects(project_id),
  FOREIGN KEY (milestone_id) REFERENCES Milestones(milestone_id),
  FOREIGN KEY (application_id) REFERENCES Applications(application_id)
);

-- 12. Certificates - FINAL 
CREATE TABLE Certificates (
  certificate_id INT PRIMARY KEY,
  verification_id INT NOT NULL,
  project_id INT NOT NULL,
  user_id INT NOT NULL,
  certificate_code VARCHAR(50) UNIQUE NOT NULL,
  issued_at DATETIME NOT NULL,
  certificate_url VARCHAR(255),
  FOREIGN KEY (verification_id) REFERENCES Verifications(verification_id),
  FOREIGN KEY (project_id) REFERENCES Projects(project_id),
  FOREIGN KEY (user_id) REFERENCES Users(user_id)
);
