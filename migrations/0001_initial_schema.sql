-- Users table
CREATE TABLE users (
    id TEXT PRIMARY KEY,
    email TEXT NOT NULL UNIQUE,
    auth_subject TEXT UNIQUE,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

-- Projects table
CREATE TABLE projects (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    name TEXT NOT NULL,
    website_url TEXT,
    public_identifier TEXT NOT NULL UNIQUE,
    status TEXT NOT NULL DEFAULT 'active',
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_projects_user_id ON projects(user_id);
CREATE INDEX idx_projects_public_identifier ON projects(public_identifier);

-- Project domains table
CREATE TABLE project_domains (
    id TEXT PRIMARY KEY,
    project_id TEXT NOT NULL,
    domain TEXT NOT NULL,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
);

CREATE INDEX idx_project_domains_project_id ON project_domains(project_id);
CREATE INDEX idx_project_domains_domain ON project_domains(domain);

-- Feedback table
CREATE TABLE feedback (
    id TEXT PRIMARY KEY,
    project_id TEXT NOT NULL,
    submission_id TEXT,
    message TEXT NOT NULL,
    visitor_email TEXT,
    page_url TEXT,
    page_title TEXT,
    user_agent TEXT,
    device_type TEXT,
    device_info TEXT,
    viewport_width INTEGER,
    viewport_height INTEGER,
    screen_width INTEGER,
    screen_height INTEGER,
    status TEXT NOT NULL DEFAULT 'unread',
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
);

CREATE INDEX idx_feedback_project_id ON feedback(project_id);
CREATE INDEX idx_feedback_project_id_created_at ON feedback(project_id, created_at);
CREATE INDEX idx_feedback_project_id_status ON feedback(project_id, status);
CREATE INDEX idx_feedback_submission_id ON feedback(submission_id);

-- Screenshots table
CREATE TABLE screenshots (
    id TEXT PRIMARY KEY,
    feedback_id TEXT NOT NULL UNIQUE,
    object_key TEXT NOT NULL,
    original_filename TEXT,
    content_type TEXT,
    size_bytes INTEGER,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY (feedback_id) REFERENCES feedback(id) ON DELETE CASCADE
);

-- Project usage table
CREATE TABLE project_usage (
    project_id TEXT PRIMARY KEY,
    included_credits INTEGER NOT NULL DEFAULT 0,
    purchased_credits INTEGER NOT NULL DEFAULT 0,
    used_credits INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
);

-- Credit transactions table
CREATE TABLE credit_transactions (
    id TEXT PRIMARY KEY,
    project_id TEXT NOT NULL,
    type TEXT NOT NULL,
    amount INTEGER NOT NULL,
    reference TEXT,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
);

CREATE INDEX idx_credit_transactions_project_id ON credit_transactions(project_id);
