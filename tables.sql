CREATE TABLE documents (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  author_id TEXT,  
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  title TEXT
);


CREATE TABLE questions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  document_id INTEGER,
  type TEXT,         -- 'multiple_choice', 'true_false', 'open', etc.
  text TEXT,
  correct_answer TEXT, -- Para preguntas abiertas o verdadero/falso
  FOREIGN KEY(document_id) REFERENCES documents(id)
);

CREATE TABLE options (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  question_id INTEGER,
  text TEXT,
  is_correct BOOLEAN,
  FOREIGN KEY(question_id) REFERENCES questions(id)
);



CREATE TABLE article_blocks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  document_id INTEGER,
  type TEXT,         -- 'title', 'paragraph', 'image', 'video'
  content TEXT,      -- texto o URL
  block_order INTEGER,
  FOREIGN KEY(document_id) REFERENCES documents(id)
);