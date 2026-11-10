CREATE TABLE Users (
  user_id INT AUTO_INCREMENT PRIMARY KEY,
  full_name VARCHAR(100) NOT NULL,
  email VARCHAR(100) UNIQUE NOT NULL,
  phone VARCHAR(20) UNIQUE NOT NULL,
  password_hash VARCHAR(255),
  role ENUM('Freelancer', 'client', 'admin') NOT NULL,
  city VARCHAR(100) NOT NULL,
  linkedin_url VARCHAR(255),
  trust_score DECIMAL(5,2) DEFAULT 0.00,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE Organizations (
  org_id INT AUTO_INCREMENT PRIMARY KEY,
  org_name VARCHAR(100) NOT NULL,
  industry VARCHAR(100) NOT NULL,
  gst_no VARCHAR(15) UNIQUE,      
  website VARCHAR(255),
  city VARCHAR(100) NOT NULL,
  owner_id INT NOT NULL,
  FOREIGN KEY (owner_id) REFERENCES Users(user_id) ON DELETE CASCADE
);

CREATE TABLE Projects (
  project_id INT AUTO_INCREMENT PRIMARY KEY,
  org_id INT,
  title VARCHAR(150) NOT NULL,
  description TEXT,
  budget DECIMAL(10,2),
  status ENUM('open','in_progress','completed') DEFAULT 'open',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (org_id) REFERENCES Organizations(org_id)
);

CREATE TABLE Skills (
  skill_id INT AUTO_INCREMENT PRIMARY KEY,
  skill_name VARCHAR(50) UNIQUE NOT NULL
);

CREATE TABLE UserSkills (
  user_id INT,
  skill_id INT,
  PRIMARY KEY (user_id, skill_id),
  FOREIGN KEY (user_id) REFERENCES Users(user_id),
  FOREIGN KEY (skill_id) REFERENCES Skills(skill_id)
);

CREATE TABLE Applications (
  application_id INT AUTO_INCREMENT PRIMARY KEY,
  project_id INT,
  user_id INT,
  status ENUM('applied','accepted','rejected') DEFAULT 'applied',
  UNIQUE (project_id, user_id),
  FOREIGN KEY (project_id) REFERENCES Projects(project_id),
  FOREIGN KEY (user_id) REFERENCES Users(user_id)
);

CREATE TABLE Milestones (
  milestone_id INT AUTO_INCREMENT PRIMARY KEY,
  project_id INT,
  title VARCHAR(100),
  due_date DATE,
  FOREIGN KEY (project_id) REFERENCES Projects(project_id)
);

CREATE TABLE Submissions (
  submission_id INT AUTO_INCREMENT PRIMARY KEY,
  project_id INT,
  user_id INT,
  file_url VARCHAR(255),
  version_no INT DEFAULT 1,
  submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (project_id) REFERENCES Projects(project_id),
  FOREIGN KEY (user_id) REFERENCES Users(user_id)
);

CREATE TABLE Reviews (
  review_id INT AUTO_INCREMENT PRIMARY KEY,
  project_id INT,
  reviewer_id INT,
  rating INT CHECK (rating BETWEEN 1 AND 5),
  comment TEXT,
  status ENUM('approved','rejected') DEFAULT 'approved',
  FOREIGN KEY (project_id) REFERENCES Projects(project_id)
);

CREATE TABLE Transactions (
  transaction_id INT AUTO_INCREMENT PRIMARY KEY,
  project_id INT,
  user_id INT,
  amount DECIMAL(10,2) NOT NULL,
  status ENUM('pending','success','failed') DEFAULT 'success',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (project_id) REFERENCES Projects(project_id),
  FOREIGN KEY (user_id) REFERENCES Users(user_id)
);

CREATE TABLE VerifiedExperience (
  ve_id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT,
  project_id INT UNIQUE,
  certificate_url VARCHAR(255),
  issued_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES Users(user_id),
  FOREIGN KEY (project_id) REFERENCES Projects(project_id)
);
