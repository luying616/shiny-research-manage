-- ==================== 科研项目管理系统数据库初始化脚本 ====================
-- 功能：创建所有必要的数据库表和索引
-- 数据库：PostgreSQL 12+
-- 编码：UTF-8
-- =======================================================================

-- ==================== 创建 Schema ====================
CREATE SCHEMA IF NOT EXISTS projects;
CREATE SCHEMA IF NOT EXISTS auth;

-- ==================== 认证模块表 ====================

-- 1. 用户表
CREATE TABLE IF NOT EXISTS auth.users (
  user_id SERIAL PRIMARY KEY,
  username VARCHAR(100) NOT NULL UNIQUE,
  email VARCHAR(100) NOT NULL UNIQUE,
  password_hash VARCHAR(64) NOT NULL,
  role VARCHAR(20) DEFAULT 'analyst' CHECK (role IN ('admin', 'manager', 'analyst', 'viewer')),
  department VARCHAR(100),
  is_active BOOLEAN DEFAULT TRUE,
  is_server_account BOOLEAN DEFAULT FALSE,
  work_dir VARCHAR(500),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  last_activity TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  notes TEXT
);

-- ==================== 项目管理模块表 ====================

-- 2. 项目类型字典表
CREATE TABLE IF NOT EXISTS projects.project_types (
  type_id SERIAL PRIMARY KEY,
  type_code VARCHAR(20) UNIQUE NOT NULL,
  type_name VARCHAR(100) NOT NULL,
  description TEXT,
  sort_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE
);

-- 3. 研究阶段字典表
CREATE TABLE IF NOT EXISTS projects.research_stages (
  stage_id SERIAL PRIMARY KEY,
  stage_code VARCHAR(20) UNIQUE NOT NULL,
  stage_name VARCHAR(100) NOT NULL,
  description TEXT,
  sort_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE
);

-- 4. 项目状态字典表
CREATE TABLE IF NOT EXISTS projects.project_statuses (
  status_id SERIAL PRIMARY KEY,
  status_code VARCHAR(20) UNIQUE NOT NULL,
  status_name VARCHAR(100) NOT NULL,
  description TEXT,
  sort_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE
);

-- 5. 项目主表（核心信息）
CREATE TABLE IF NOT EXISTS projects.projects (
  project_id SERIAL PRIMARY KEY,
  project_name VARCHAR(255) NOT NULL UNIQUE,
  project_code VARCHAR(50) UNIQUE,
  project_type_id INTEGER REFERENCES projects.project_types(type_id),
  research_stage_id INTEGER REFERENCES projects.research_stages(stage_id),
  priority_level VARCHAR(20) CHECK (priority_level IN ('high', 'medium', 'low')),
  budget DECIMAL(15,2),
  start_date DATE,
  end_date DATE,
  status_id INTEGER REFERENCES projects.project_statuses(status_id),
  description TEXT,
  objectives TEXT,
  deliverables TEXT,
  risks TEXT,
  created_by INTEGER REFERENCES auth.users(user_id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  is_active BOOLEAN DEFAULT TRUE
);

-- 6. 研究人员表（内部人员）
CREATE TABLE IF NOT EXISTS projects.researchers (
  researcher_id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  title VARCHAR(50),
  department VARCHAR(100),
  email VARCHAR(100),
  phone VARCHAR(50),
  employee_id VARCHAR(50),
  research_interests TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  is_active BOOLEAN DEFAULT TRUE,
  UNIQUE(name, email)
);

-- 7. 项目-研究人员关联表（多对多）
CREATE TABLE IF NOT EXISTS projects.project_researchers (
  project_id INTEGER REFERENCES projects.projects(project_id) ON DELETE CASCADE,
  researcher_id INTEGER REFERENCES projects.researchers(researcher_id) ON DELETE CASCADE,
  role VARCHAR(50) NOT NULL,
  responsibility TEXT,
  workload_percentage DECIMAL(5,2) DEFAULT 100.00,
  start_date DATE,
  end_date DATE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (project_id, researcher_id, role)
);

-- 8. 研究领域表
CREATE TABLE IF NOT EXISTS projects.research_fields (
  field_id SERIAL PRIMARY KEY,
  field_code VARCHAR(50) UNIQUE NOT NULL,
  field_name VARCHAR(200) NOT NULL,
  category VARCHAR(100),
  description TEXT,
  parent_id INTEGER REFERENCES projects.research_fields(field_id),
  sort_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE
);

-- 9. 项目-研究领域关联表（多对多）
CREATE TABLE IF NOT EXISTS projects.project_fields (
  project_id INTEGER REFERENCES projects.projects(project_id) ON DELETE CASCADE,
  field_id INTEGER REFERENCES projects.research_fields(field_id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (project_id, field_id)
);

-- 10. 经费来源字典表
CREATE TABLE IF NOT EXISTS projects.funding_sources (
  source_id SERIAL PRIMARY KEY,
  source_code VARCHAR(50) UNIQUE NOT NULL,
  source_name VARCHAR(200) NOT NULL,
  source_type VARCHAR(50),
  description TEXT,
  is_active BOOLEAN DEFAULT TRUE
);

-- 11. 项目-经费来源关联表
CREATE TABLE IF NOT EXISTS projects.project_funding (
  project_id INTEGER REFERENCES projects.projects(project_id) ON DELETE CASCADE,
  source_id INTEGER REFERENCES projects.funding_sources(source_id) ON DELETE CASCADE,
  amount DECIMAL(15,2) NOT NULL,
  fiscal_year INTEGER,
  grant_number VARCHAR(100),
  start_date DATE,
  end_date DATE,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (project_id, source_id)
);

-- 12. 合作类型字典表
CREATE TABLE IF NOT EXISTS projects.collaboration_types (
  type_id SERIAL PRIMARY KEY,
  type_code VARCHAR(20) UNIQUE NOT NULL,
  type_name VARCHAR(100) NOT NULL,
  description TEXT,
  sort_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE
);

-- 13. 项目-合作类型关联表
CREATE TABLE IF NOT EXISTS projects.project_collaboration (
  project_id INTEGER REFERENCES projects.projects(project_id) ON DELETE CASCADE,
  type_id INTEGER REFERENCES projects.collaboration_types(type_id) ON DELETE CASCADE,
  details TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (project_id, type_id)
);

-- 14. 项目里程碑表
CREATE TABLE IF NOT EXISTS projects.project_milestones (
  milestone_id SERIAL PRIMARY KEY,
  project_id INTEGER REFERENCES projects.projects(project_id) ON DELETE CASCADE,
  milestone_name VARCHAR(200) NOT NULL,
  description TEXT,
  milestone_type VARCHAR(50),
  due_date DATE,
  completed_date DATE,
  status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed', 'delayed', 'cancelled')),
  completion_percentage DECIMAL(5,2) DEFAULT 0,
  dependencies TEXT,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 15. 项目文档表
CREATE TABLE IF NOT EXISTS projects.project_documents (
  document_id SERIAL PRIMARY KEY,
  project_id INTEGER REFERENCES projects.projects(project_id) ON DELETE CASCADE,
  document_type VARCHAR(50) NOT NULL,
  document_name VARCHAR(200) NOT NULL,
  document_number VARCHAR(100),
  file_path VARCHAR(500),
  file_size BIGINT,
  mime_type VARCHAR(100),
  version VARCHAR(20),
  uploader_id INTEGER REFERENCES auth.users(user_id),
  upload_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  description TEXT,
  tags TEXT[],
  is_confidential BOOLEAN DEFAULT FALSE,
  valid_until DATE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 16. 项目预算明细表
CREATE TABLE IF NOT EXISTS projects.project_budget_items (
  item_id SERIAL PRIMARY KEY,
  project_id INTEGER REFERENCES projects.projects(project_id) ON DELETE CASCADE,
  budget_category VARCHAR(100) NOT NULL,
  item_name VARCHAR(200) NOT NULL,
  description TEXT,
  unit_price DECIMAL(15,2),
  quantity DECIMAL(10,2),
  unit VARCHAR(50),
  total_amount DECIMAL(15,2),
  currency VARCHAR(3) DEFAULT 'CNY',
  fiscal_year INTEGER,
  status VARCHAR(20) DEFAULT 'planned' CHECK (status IN ('planned', 'approved', 'ordered', 'received', 'paid', 'cancelled')),
  supplier VARCHAR(200),
  order_number VARCHAR(100),
  payment_date DATE,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 17. 项目变更历史表
CREATE TABLE IF NOT EXISTS projects.project_changes (
  change_id SERIAL PRIMARY KEY,
  project_id INTEGER REFERENCES projects.projects(project_id) ON DELETE CASCADE,
  change_type VARCHAR(50) NOT NULL,
  table_name VARCHAR(100),
  record_id INTEGER,
  field_name VARCHAR(100),
  old_value TEXT,
  new_value TEXT,
  change_reason TEXT,
  changed_by INTEGER REFERENCES auth.users(user_id),
  changed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  ip_address INET,
  user_agent TEXT
);

-- 18. 项目评论/讨论表
CREATE TABLE IF NOT EXISTS projects.project_comments (
  comment_id SERIAL PRIMARY KEY,
  project_id INTEGER REFERENCES projects.projects(project_id) ON DELETE CASCADE,
  parent_comment_id INTEGER REFERENCES projects.project_comments(comment_id) ON DELETE CASCADE,
  user_id INTEGER REFERENCES auth.users(user_id),
  content TEXT NOT NULL,
  is_internal BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ==================== 创建索引 ====================
CREATE INDEX IF NOT EXISTS idx_projects_type ON projects.projects(project_type_id);
CREATE INDEX IF NOT EXISTS idx_projects_status ON projects.projects(status_id);
CREATE INDEX IF NOT EXISTS idx_projects_active ON projects.projects(is_active);
CREATE INDEX IF NOT EXISTS idx_projects_code ON projects.projects(project_code);

CREATE INDEX IF NOT EXISTS idx_project_researchers_project ON projects.project_researchers(project_id);
CREATE INDEX IF NOT EXISTS idx_project_researchers_person ON projects.project_researchers(researcher_id);
CREATE INDEX IF NOT EXISTS idx_project_researchers_role ON projects.project_researchers(role);

CREATE INDEX IF NOT EXISTS idx_project_fields_project ON projects.project_fields(project_id);
CREATE INDEX IF NOT EXISTS idx_project_fields_field ON projects.project_fields(field_id);

CREATE INDEX IF NOT EXISTS idx_project_funding_project ON projects.project_funding(project_id);
CREATE INDEX IF NOT EXISTS idx_project_funding_source ON projects.project_funding(source_id);

CREATE INDEX IF NOT EXISTS idx_project_milestones_project ON projects.project_milestones(project_id);
CREATE INDEX IF NOT EXISTS idx_project_milestones_status ON projects.project_milestones(status);
CREATE INDEX IF NOT EXISTS idx_project_milestones_due ON projects.project_milestones(due_date);

CREATE INDEX IF NOT EXISTS idx_project_documents_project ON projects.project_documents(project_id);
CREATE INDEX IF NOT EXISTS idx_project_documents_type ON projects.project_documents(document_type);

CREATE INDEX IF NOT EXISTS idx_project_budget_project ON projects.project_budget_items(project_id);
CREATE INDEX IF NOT EXISTS idx_project_budget_category ON projects.project_budget_items(budget_category);
CREATE INDEX IF NOT EXISTS idx_project_budget_status ON projects.project_budget_items(status);

CREATE INDEX IF NOT EXISTS idx_project_changes_project ON projects.project_changes(project_id);
CREATE INDEX IF NOT EXISTS idx_project_changes_time ON projects.project_changes(changed_at);
CREATE INDEX IF NOT EXISTS idx_project_changes_user ON projects.project_changes(changed_by);

CREATE INDEX IF NOT EXISTS idx_project_comments_project ON projects.project_comments(project_id);
CREATE INDEX IF NOT EXISTS idx_project_comments_time ON projects.project_comments(created_at);

-- ==================== 插入初始数据 ====================

-- 插入项目类型
INSERT INTO projects.project_types (type_code, type_name, description, sort_order) VALUES
  ('JC', '基础研究', '基础科学研究项目', 1),
  ('YY', '应用研究', '应用型研究项目', 2),
  ('LC', '临床研究', '临床医学研究项目', 3),
  ('SJ', '数据项目', '数据分析和管理项目', 4),
  ('ZY', '资源项目', '资源建设和共享项目', 5)
ON CONFLICT (type_code) DO NOTHING;

-- 插入研究阶段
INSERT INTO projects.research_stages (stage_code, stage_name, description, sort_order) VALUES
  ('initiation', '立项阶段', '项目立项和规划阶段', 1),
  ('implementation', '实施阶段', '项目执行和研究阶段', 2),
  ('mid_term', '中期评估', '项目中期评估阶段', 3),
  ('closing', '结题阶段', '项目结题准备阶段', 4),
  ('completed', '已结题', '项目已完成并结题', 5)
ON CONFLICT (stage_code) DO NOTHING;

-- 插入项目状态
INSERT INTO projects.project_statuses (status_code, status_name, description, sort_order) VALUES
  ('planning', '规划中', '项目正在规划阶段', 1),
  ('in_progress', '进行中', '项目正在执行中', 2),
  ('on_hold', '暂停', '项目暂时暂停', 3),
  ('completed', '已完成', '项目已完成', 4),
  ('cancelled', '已取消', '项目已取消', 5)
ON CONFLICT (status_code) DO NOTHING;

-- 插入合作类型
INSERT INTO projects.collaboration_types (type_code, type_name, description, sort_order) VALUES
  ('independent', '独立研究', '独立开展的研究项目', 1),
  ('internal', '院内合作', '院内跨部门合作项目', 2),
  ('external', '院外合作', '与院外机构合作项目', 3),
  ('international', '国际合作', '国际合作研究项目', 4)
ON CONFLICT (type_code) DO NOTHING;

-- 插入研究领域
INSERT INTO projects.research_fields (field_code, field_name, category, sort_order) VALUES
  ('BASIC_MED', '基础医学', '基础医学', 1),
  ('CLINICAL_MED', '临床医学', '临床医学', 2),
  ('PUBLIC_HEALTH', '公共卫生', '公共卫生', 3),
  ('PHARMACY', '药学', '药学', 4),
  ('BIOMED_ENG', '生物医学工程', '生物医学工程', 5),
  ('NURSING', '护理学', '护理学', 6),
  ('TCM', '中医学', '中医学', 7),
  ('OTHER', '其他', '其他研究领域', 99)
ON CONFLICT (field_code) DO NOTHING;

-- 插入经费来源示例
INSERT INTO projects.funding_sources (source_code, source_name, source_type) VALUES
  ('NSFC', '国家自然科学基金', '国家级'),
  ('PROVINCIAL', '省级科研基金', '省级'),
  ('MUNICIPAL', '市级科研基金', '市级'),
  ('HOSPITAL', '医院自筹', '医院'),
  ('ENTERPRISE', '企业合作', '企业')
ON CONFLICT (source_code) DO NOTHING;

-- 插入默认管理员用户（密码：admin123，SHA-256哈希值）
-- 注意：这是示例密码，实际部署时应该更改
INSERT INTO auth.users (username, email, password_hash, role, department, is_active) VALUES
  ('admin', 'admin@hospital.com', '240be518fabd2724ddb6f04eeb1da5967448d7e831c08c8fa822809f74c720a9', 'admin', '系统管理', TRUE)
ON CONFLICT (username) DO NOTHING;

-- ==================== 创建触发器（自动更新updated_at） ====================

-- 创建更新时间戳函数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 为需要的表创建触发器
CREATE TRIGGER update_projects_updated_at BEFORE UPDATE ON projects.projects
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_researchers_updated_at BEFORE UPDATE ON projects.researchers
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_project_researchers_updated_at BEFORE UPDATE ON projects.project_researchers
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON auth.users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ==================== 完成 ====================
-- 数据库初始化完成
