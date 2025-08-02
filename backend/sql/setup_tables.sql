-- Script SQL para criar tabelas do KM$ Backend
-- Execute este SQL no dashboard do Supabase

-- 1. Criar tabela trabalho
CREATE TABLE IF NOT EXISTS trabalho (
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

-- Índices para performance na tabela trabalho
CREATE INDEX IF NOT EXISTS idx_trabalho_user_id ON trabalho(user_id);
CREATE INDEX IF NOT EXISTS idx_trabalho_data ON trabalho(data);
CREATE INDEX IF NOT EXISTS idx_trabalho_user_data ON trabalho(user_id, data);

-- 2. Criar tabela gastos
CREATE TABLE IF NOT EXISTS gastos (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  data DATE NOT NULL,
  categoria VARCHAR(50) NOT NULL,
  valor DECIMAL(10,2) NOT NULL,
  descricao TEXT,
  local VARCHAR(100),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Índices para performance na tabela gastos
CREATE INDEX IF NOT EXISTS idx_gastos_user_id ON gastos(user_id);
CREATE INDEX IF NOT EXISTS idx_gastos_data ON gastos(data);
CREATE INDEX IF NOT EXISTS idx_gastos_categoria ON gastos(categoria);
CREATE INDEX IF NOT EXISTS idx_gastos_user_data ON gastos(user_id, data);

-- 3. Criar tabela manutencoes
CREATE TABLE IF NOT EXISTS manutencoes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  data DATE NOT NULL,
  tipo VARCHAR(50) NOT NULL,
  valor DECIMAL(10,2) NOT NULL,
  quilometragem INTEGER NOT NULL,
  descricao TEXT,
  oficina VARCHAR(100),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Índices para performance na tabela manutencoes
CREATE INDEX IF NOT EXISTS idx_manutencoes_user_id ON manutencoes(user_id);
CREATE INDEX IF NOT EXISTS idx_manutencoes_data ON manutencoes(data);
CREATE INDEX IF NOT EXISTS idx_manutencoes_tipo ON manutencoes(tipo);
CREATE INDEX IF NOT EXISTS idx_manutencoes_user_data ON manutencoes(user_id, data);

-- 4. Habilitar Row Level Security (RLS) para proteger dados dos usuários
ALTER TABLE trabalho ENABLE ROW LEVEL SECURITY;
ALTER TABLE gastos ENABLE ROW LEVEL SECURITY;
ALTER TABLE manutencoes ENABLE ROW LEVEL SECURITY;

-- 5. Criar políticas RLS para trabalho
CREATE POLICY "Users can view own trabalho records" ON trabalho
    FOR SELECT USING (auth.uid()::text = user_id::text);

CREATE POLICY "Users can insert own trabalho records" ON trabalho
    FOR INSERT WITH CHECK (auth.uid()::text = user_id::text);

CREATE POLICY "Users can update own trabalho records" ON trabalho
    FOR UPDATE USING (auth.uid()::text = user_id::text);

CREATE POLICY "Users can delete own trabalho records" ON trabalho
    FOR DELETE USING (auth.uid()::text = user_id::text);

-- 6. Criar políticas RLS para gastos
CREATE POLICY "Users can view own gastos records" ON gastos
    FOR SELECT USING (auth.uid()::text = user_id::text);

CREATE POLICY "Users can insert own gastos records" ON gastos
    FOR INSERT WITH CHECK (auth.uid()::text = user_id::text);

CREATE POLICY "Users can update own gastos records" ON gastos
    FOR UPDATE USING (auth.uid()::text = user_id::text);

CREATE POLICY "Users can delete own gastos records" ON gastos
    FOR DELETE USING (auth.uid()::text = user_id::text);

-- 7. Criar políticas RLS para manutencoes
CREATE POLICY "Users can view own manutencoes records" ON manutencoes
    FOR SELECT USING (auth.uid()::text = user_id::text);

CREATE POLICY "Users can insert own manutencoes records" ON manutencoes
    FOR INSERT WITH CHECK (auth.uid()::text = user_id::text);

CREATE POLICY "Users can update own manutencoes records" ON manutencoes
    FOR UPDATE USING (auth.uid()::text = user_id::text);

CREATE POLICY "Users can delete own manutencoes records" ON manutencoes
    FOR DELETE USING (auth.uid()::text = user_id::text);

-- 8. Verificar se as tabelas foram criadas corretamente
SELECT 
    tablename,
    schemaname,
    hasindexes,
    hastriggers,
    hasrules
FROM pg_tables 
WHERE tablename IN ('trabalho', 'gastos', 'manutencoes')
AND schemaname = 'public';

-- 9. Verificar índices criados
SELECT 
    indexname,
    tablename,
    indexdef
FROM pg_indexes 
WHERE tablename IN ('trabalho', 'gastos', 'manutencoes')
AND schemaname = 'public'
ORDER BY tablename, indexname;