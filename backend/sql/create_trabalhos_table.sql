-- Script SQL para criar tabela TRABALHOS (plural) no Supabase
-- Execute este SQL no dashboard do Supabase

-- 1. Criar tabela trabalhos (plural)
CREATE TABLE IF NOT EXISTS trabalhos (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  data DATE NOT NULL,
  ganhos DECIMAL(10,2) NOT NULL,
  quilometragem_inicial INTEGER NOT NULL,
  quilometragem_final INTEGER NOT NULL,
  horas_trabalhadas DECIMAL(4,2) NOT NULL,
  observacoes TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Índices para performance na tabela trabalhos
CREATE INDEX IF NOT EXISTS idx_trabalhos_user_id ON trabalhos(user_id);
CREATE INDEX IF NOT EXISTS idx_trabalhos_data ON trabalhos(data);
CREATE INDEX IF NOT EXISTS idx_trabalhos_user_data ON trabalhos(user_id, data);

-- Habilitar Row Level Security (RLS)
ALTER TABLE trabalhos ENABLE ROW LEVEL SECURITY;

-- Criar políticas RLS para trabalhos
CREATE POLICY "Users can view own trabalhos records" ON trabalhos
    FOR SELECT USING (auth.uid()::text = user_id::text);

CREATE POLICY "Users can insert own trabalhos records" ON trabalhos
    FOR INSERT WITH CHECK (auth.uid()::text = user_id::text);

CREATE POLICY "Users can update own trabalhos records" ON trabalhos
    FOR UPDATE USING (auth.uid()::text = user_id::text);

CREATE POLICY "Users can delete own trabalhos records" ON trabalhos
    FOR DELETE USING (auth.uid()::text = user_id::text);

-- Verificar se a tabela foi criada
SELECT 
    tablename,
    schemaname
FROM pg_tables 
WHERE tablename = 'trabalhos'
AND schemaname = 'public';