-- Users ke liye
INSERT INTO Users (full_name, email, role, phone_number, city) VALUES
('Kalpana Singhmar', 'kalpana@example.com', 'freelancer', '9999999999', 'Karnal'),
('Chetan Vashishat', 'chetan@buywise.ai', 'client', '8888888888', 'Delhi'),
('Nitin Sharma', 'Nitin@proofwork.com', 'admin', '7777777777', 'Panipat'),
('Devi Sharma', 'devi@dev.com', 'freelancer', '6666666666', 'Karnal');

-- Organizations
ALTER TABLE Organizations MODIFY city VARCHAR(100) NULL;
INSERT INTO Organizations (org_name, owner_id) VALUES
('BuyWise AI', 2);

-- Projects
INSERT INTO Projects (org_id, title, description, budget, status) VALUES
(1, 'Website Redesign', 'Redesign company landing page with React', 25000.00, 'open'),
(1, 'AI Chatbot', 'Build AI assistant for customer support', 50000.00, 'in_progress');

-- Skills
INSERT INTO Skills (skill_name) VALUES
('React'), ('Python'), ('SQL'), ('UI/UX');

-- UserSkills
INSERT INTO UserSkills (user_id, skill_id) VALUES
(1, 1), (1, 3), (4, 1), (4, 2);

-- Applications - UNIQUE proof
INSERT INTO Applications (project_id, user_id, status) VALUES
(1, 1, 'applied'),
(2, 4, 'accepted');

-- Milestones
INSERT INTO Milestones (project_id, title, due_date) VALUES
(2, 'Phase 1 - UI Done', '2026-11-20');

-- Transactions
INSERT INTO Transactions (project_id, user_id, amount, status) VALUES
(2, 4, 10000.00, 'success');
