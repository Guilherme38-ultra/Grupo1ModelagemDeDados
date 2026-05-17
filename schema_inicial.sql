-- Enums
CREATE TYPE tipo_conta AS ENUM (
    'corrente',
    'poupanca',
    'digital'
);

CREATE TYPE status_conta AS ENUM (
    'ativo',
    'inativo'
);

CREATE TYPE tipo_cartao AS ENUM (
    'credito',
    'debito',
    'pre-pago'
);

CREATE TYPE status_lojista AS ENUM (
    'ativo',
    'inativo'
);

CREATE TYPE status_categoria AS ENUM (
    'ativo',
    'inativo'
);

CREATE TYPE status_transportadora AS ENUM (
    'ativo',
    'inativo'
);

CREATE TYPE status_produto AS ENUM (
    'ativo',
    'inativo'
);

CREATE TYPE status_pedido AS ENUM (
    'pendente',
    'aprovado',
    'enviado',
    'entregue',
    'cancelado'
);

CREATE TYPE status_frete AS ENUM (
    'aguardando',
    'em_transito',
    'entregue',
    'devolvido'
);

CREATE TYPE status_comissao AS ENUM (
    'pendente',
    'pago',
    'estornado'
);

CREATE TYPE status_estorno AS ENUM (
    'solicitado',
    'processando',
    'concluido',
    'rejeitado'
);

CREATE TYPE tipo_beneficiario AS ENUM (
    'cliente',
    'lojista',
    'transportadora',
    'banco'
);

CREATE TYPE status_parcela AS ENUM (
    'pendente',
    'processado',
    'falhou'
);

CREATE TYPE op_auditoria AS ENUM (
    'INSERT',
    'UPDATE',
    'DELETE'
);

CREATE TYPE tipo_op_saldo AS ENUM (
    'credito',
    'debito',
    'estorno_credito',
    'estorno_debito'
);

-- Tabelas
CREATE TABLE clientes (
    id SERIAL PRIMARY KEY,
    primeiro_nome VARCHAR(100) NOT NULL,
    ultimo_nome VARCHAR(100) NOT NULL,
    nome_usuario VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    cpf VARCHAR(14) UNIQUE NOT NULL,
    phone VARCHAR(20),
    dt_cadastro TIMESTAMP DEFAULT NOW()
);

CREATE TABLE endereco (
    id SERIAL PRIMARY KEY,
    cliente_id INT NOT NULL REFERENCES clientes(id) ON DELETE CASCADE,
    logradouro VARCHAR(200) NOT NULL,
    numero VARCHAR(20) NOT NULL,
    complemento VARCHAR(100),
    bairro VARCHAR(100) NOT NULL,
    cidade VARCHAR(100) NOT NULL,
    uf CHAR(2) NOT NULL,
    cep VARCHAR(10) NOT NULL,
    principal BOOLEAN DEFAULT FALSE
);

CREATE TABLE contas (
    id SERIAL PRIMARY KEY,
    cliente_id INT NOT NULL REFERENCES clientes(id),
    tipo tipo_conta NOT NULL,
    saldo NUMERIC(15,2) NOT NULL DEFAULT 0.00,
    status status_conta NOT NULL DEFAULT 'ativo',
    dt_abertura TIMESTAMP DEFAULT NOW()
);

CREATE TABLE cartoes (
    id SERIAL PRIMARY KEY,
    cliente_id INT NOT NULL REFERENCES clientes(id),
    tipo tipo_cartao NOT NULL,
    numero BIGINT UNIQUE NOT NULL,
    limite NUMERIC(15,2),
    dt_validade DATE NOT NULL,
    status status_cartao NOT NULL DEFAULT 'ativo'
);

CREATE TABLE lojista (
    id SERIAL PRIMARY KEY,
    cliente_id INT UNIQUE NOT NULL REFERENCES clientes(id),
    razao_social VARCHAR(200) NOT NULL,
    cnpj VARCHAR(18) UNIQUE NOT NULL,
    comissao_percentual NUMERIC(5,2) NOT NULL,
    frete_percentual NUMERIC(5,2) NOT NULL,
    avaliacao NUMERIC(3,1) CHECK (avaliacao >= 0.0 AND avaliacao <= 5.0),
    status status_lojista NOT NULL DEFAULT 'ativo'
);

CREATE TABLE categoria (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) UNIQUE NOT NULL,
    descricao TEXT,
    status status_categoria NOT NULL DEFAULT 'ativo',
    dt_criacao TIMESTAMP DEFAULT NOW()
);

CREATE TABLE transportadora (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(200) NOT NULL,
    cnpj VARCHAR(18) UNIQUE NOT NULL,
    telefone VARCHAR(20),
    status status_transportadora NOT NULL DEFAULT 'ativo'
);

CREATE TABLE transferencias (
    id SERIAL PRIMARY KEY,
    remetente INT NOT NULL REFERENCES contas(id),
    destinatario INT NOT NULL REFERENCES contas(id),
    data TIMESTAMP DEFAULT NOW(),
    valor NUMERIC(15,2) NOT NULL CHECK (valor > 0),
    descricao TEXT,
    CONSTRAINT chk_remetente_destinatario CHECK (remetente <> destinatario)
);

CREATE TABLE transacoes (
    id SERIAL PRIMARY KEY,
    conta_id INT NOT NULL REFERENCES contas(id),
    data TIMESTAMP DEFAULT NOW(),
    tipo VARCHAR(50) NOT NULL,
    valor NUMERIC(15,2) NOT NULL CHECK (valor > 0),
    status VARCHAR(50) NOT NULL,
    descricao TEXT,
    referencia_id INT
);

CREATE TABLE produto (
    id SERIAL PRIMARY KEY,
    categoria_id INT NOT NULL REFERENCES categoria(id),
    nome VARCHAR(200) NOT NULL,
    descricao TEXT NOT NULL,
    preco NUMERIC(15,2) NOT NULL CHECK (preco > 0),
    estoque INT NOT NULL CHECK (estoque >= 0),
    status status_produto NOT NULL DEFAULT 'ativo',
    dt_cadastro TIMESTAMP DEFAULT NOW()
);

CREATE TABLE pedido (
    id SERIAL PRIMARY KEY,
    cliente_id INT NOT NULL REFERENCES clientes(id),
    lojista_id INT NOT NULL REFERENCES lojista(id),
    dt_pedido TIMESTAMP DEFAULT NOW(),
    dt_entrega TIMESTAMP,
    total NUMERIC(15,2) NOT NULL,
    tp_pagamento VARCHAR(50) NOT NULL,
    status status_pedido NOT NULL DEFAULT 'pendente',
    pedido_entregue BOOLEAN DEFAULT FALSE
);

CREATE TABLE item (
    id SERIAL PRIMARY KEY,
    pedido_id INT NOT NULL REFERENCES pedido(id) ON DELETE CASCADE,
    cod_produto INT NOT NULL REFERENCES produto(id),
    preco NUMERIC(15,2) NOT NULL,
    quantidade INT NOT NULL CHECK (quantidade > 0),
    subtotal NUMERIC(15,2) GENERATED ALWAYS AS (preco * quantidade) STORED
);

CREATE TABLE frete (
    id SERIAL PRIMARY KEY,
    pedido_id INT UNIQUE NOT NULL REFERENCES pedido(id),
    transportadora_id INT NOT NULL REFERENCES transportadora(id),
    valor NUMERIC(15,2) NOT NULL,
    status status_frete NOT NULL DEFAULT 'aguardando',
    dt_despacho TIMESTAMP,
    dt_entrega_real TIMESTAMP
);

CREATE TABLE comissao (
    id SERIAL PRIMARY KEY,
    pedido_id INT UNIQUE NOT NULL REFERENCES pedido(id),
    lojista_id INT NOT NULL REFERENCES lojista(id),
    percentual NUMERIC(5,2) NOT NULL,
    valor_bruto NUMERIC(15,2) NOT NULL,
    valor_comissao NUMERIC(15,2) NOT NULL,
    valor_liquido NUMERIC(15,2) NOT NULL,
    status status_comissao NOT NULL DEFAULT 'pendente',
    dt_calculo TIMESTAMP DEFAULT NOW()
);

CREATE TABLE estorno (
    id SERIAL PRIMARY KEY,
    pedido_id INT UNIQUE NOT NULL REFERENCES pedido(id),
    solicitante_id INT NOT NULL REFERENCES clientes(id),
    motivo TEXT NOT NULL,
    valor_total NUMERIC(15,2) NOT NULL,
    status status_estorno NOT NULL DEFAULT 'solicitado',
    dt_solicitacao TIMESTAMP DEFAULT NOW(),
    dt_processamento TIMESTAMP
);

CREATE TABLE estorno_parcela (
    id SERIAL PRIMARY KEY,
    estorno_id INT NOT NULL REFERENCES estorno(id),
    tipo_beneficiario tipo_beneficiario NOT NULL,
    valor NUMERIC(15,2) NOT NULL,
    status status_parcela NOT NULL DEFAULT 'pendente',
    dt_processamento TIMESTAMP,
    observacao TEXT
);

CREATE TABLE auditoria (
    id BIGSERIAL PRIMARY KEY,
    tabela_nome VARCHAR(100) NOT NULL,
    operacao op_auditoria NOT NULL,
    dado_antigo JSONB,
    dado_novo JSONB,
    usuario_bd VARCHAR(100) DEFAULT CURRENT_USER,
    dt_operacao TIMESTAMP DEFAULT NOW()
);

CREATE TABLE log_pedido (
    id SERIAL PRIMARY KEY,
    pedido_id INT NOT NULL REFERENCES pedido(id),
    status_anterior status_pedido,
    status_novo status_pedido NOT NULL,
    observacao TEXT,
    usuario VARCHAR(100) DEFAULT CURRENT_USER,
    dt_alteracao TIMESTAMP DEFAULT NOW()
);

CREATE TABLE log_saldo (
    id BIGSERIAL PRIMARY KEY,
    conta_id INT NOT NULL REFERENCES contas(id),
    tipo_operacao tipo_op_saldo NOT NULL,
    valor_anterior NUMERIC(15,2) NOT NULL,
    valor_movimentado NUMERIC(15,2) NOT NULL,
    valor_posterior NUMERIC(15,2) NOT NULL,
    referencia_tipo VARCHAR(50) NOT NULL,
    referencia_id INT NOT NULL,
    dt_movimentacao TIMESTAMP DEFAULT NOW()
);

CREATE TABLE log_transacao (
    id BIGSERIAL PRIMARY KEY,
    transacao_id INT NOT NULL REFERENCES transacoes(id),
    evento VARCHAR(100) NOT NULL,
    status_anterior VARCHAR(50),
    status_novo VARCHAR(50) NOT NULL,
    dado_snapshot JSONB NOT NULL,
    usuario VARCHAR(100) DEFAULT CURRENT_USER,
    dt_evento TIMESTAMP DEFAULT NOW()
);

-- FUNCTIONS


CREATE OR REPLACE FUNCTION fn_calcular_divisao_estorno(p_estorno_id INT)
RETURNS VOID AS $$
DECLARE
    v_pedido_id INT;
    v_total_pedido NUMERIC(15,2);
    v_valor_frete NUMERIC(15,2);
    v_valor_liquido NUMERIC(15,2);
    v_valor_comissao NUMERIC(15,2);
BEGIN
    SELECT pedido_id INTO v_pedido_id
    FROM estorno
    WHERE id = p_estorno_id;

    SELECT total INTO v_total_pedido
    FROM pedido
    WHERE id = v_pedido_id;

    SELECT COALESCE(valor, 0.00) INTO v_valor_frete
    FROM frete
    WHERE pedido_id = v_pedido_id;

    SELECT valor_liquido, valor_comissao INTO v_valor_liquido, v_valor_comissao
    FROM comissao
    WHERE pedido_id = v_pedido_id;
    
    INSERT INTO estorno_parcela (estorno_id, tipo_beneficiario, valor, status, observacao)
    VALUES (p_estorno_id, 'cliente', v_total_pedido, 'pendente', 'Devolução integral ao cliente');

    INSERT INTO estorno_parcela (estorno_id, tipo_beneficiario, valor, status, observacao)
    VALUES (p_estorno_id, 'lojista', v_valor_liquido, 'pendente', 'Devolução do valor líquido do produto');

    INSERT INTO estorno_parcela (estorno_id, tipo_beneficiario, valor, status, observacao)
    VALUES (p_estorno_id, 'banco', v_valor_comissao, 'pendente', 'Devolução da taxa de comissão');

    INSERT INTO estorno_parcela (estorno_id, tipo_beneficiario, valor, status, observacao)
    VALUES (p_estorno_id, 'transportadora', v_valor_frete, 'pendente', 'Devolução do custo de frete');

END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_tg_cancelamento_pedido()
RETURNS TRIGGER AS $$
DECLARE
    v_estorno_id INT;
    v_conta_cliente_id INT;
BEGIN
    INSERT INTO auditoria (tabela_nome, operacao, dado_antigo, dado_novo, usuario_bd)
    VALUES (
        TG_TABLE_NAME,
        TG_OP::op_auditoria,
        row_to_json(OLD)::jsonb,
        row_to_json(NEW)::jsonb,
        CURRENT_USER
    );

    IF NEW.status = 'cancelado' AND OLD.status <> 'cancelado' THEN

        INSERT INTO estorno (pedido_id, solicitante_id, motivo, valor_total, status)
        VALUES (NEW.id, NEW.cliente_id, 'Cancelamento processado via sistema', NEW.total, 'processando')
        RETURNING id INTO v_estorno_id;
        PERFORM fn_calcular_divisao_estorno(v_estorno_id);
        UPDATE frete SET status = 'devolvido' WHERE pedido_id = NEW.id;
        UPDATE comissao SET status = 'estornado' WHERE pedido_id = NEW.id;
        SELECT id INTO v_conta_cliente_id FROM contas WHERE cliente_id = NEW.cliente_id LIMIT 1;
        IF v_conta_cliente_id IS NOT NULL THEN
            UPDATE contas
            SET saldo = saldo + NEW.total
            WHERE id = v_conta_cliente_id;
            INSERT INTO log_saldo (
                conta_id, tipo_operacao, valor_anterior,
                valor_movimentado, valor_posterior,
                referencia_tipo, referencia_id
            )
            SELECT
                v_conta_cliente_id, 'estorno_credito', saldo - NEW.total,
                NEW.total, saldo,
                'estorno', v_estorno_id
            FROM contas WHERE id = v_conta_cliente_id;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_tg_log_pedido()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO log_pedido (pedido_id, status_anterior, status_novo, observacao)
        VALUES (NEW.id, NULL, NEW.status, 'Pedido criado no sistema');
    ELSIF (TG_OP = 'UPDATE' AND OLD.status IS DISTINCT FROM NEW.status) THEN
        INSERT INTO log_pedido (pedido_id, status_anterior, status_novo, observacao)
        VALUES (NEW.id, OLD.status, NEW.status, 'Status atualizado automaticamente');
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_tg_log_transacao()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO log_transacao (transacao_id, evento, status_anterior, status_novo, dado_snapshot)
        VALUES (NEW.id, 'criada', NULL, NEW.status, row_to_json(NEW)::jsonb);
        
    ELSIF (TG_OP = 'UPDATE' AND OLD.status IS DISTINCT FROM NEW.status) THEN
        INSERT INTO log_transacao (transacao_id, evento, status_anterior, status_novo, dado_snapshot)
        VALUES (NEW.id, 'atualizada', OLD.status, NEW.status, row_to_json(NEW)::jsonb);
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_tg_controle_estoque()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        UPDATE produto
        SET estoque = estoque - NEW.quantidade
        WHERE id = NEW.cod_produto;
        RETURN NEW;
    ELSIF (TG_OP = 'DELETE') THEN
        UPDATE produto
        SET estoque = estoque + OLD.quantidade
        WHERE id = OLD.cod_produto;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_tg_gerar_comissao()
RETURNS TRIGGER AS $$
DECLARE
    v_lojista_id INT;
    v_total_pedido NUMERIC(15,2);
    v_percentual NUMERIC(5,2);
    v_valor_bruto NUMERIC(15,2);
    v_valor_comissao NUMERIC(15,2);
    v_valor_liquido NUMERIC(15,2);
BEGIN
    SELECT p.lojista_id, p.total, l.comissao_percentual
    INTO v_lojista_id, v_total_pedido, v_percentual
    FROM pedido p
    JOIN lojista l ON p.lojista_id = l.id
    WHERE p.id = NEW.pedido_id;
    v_valor_bruto := v_total_pedido - NEW.valor;
    v_valor_comissao := (v_valor_bruto * v_percentual) / 100;
    v_valor_liquido := v_valor_bruto - v_valor_comissao;
    INSERT INTO comissao (pedido_id, lojista_id, percentual, valor_bruto, valor_comissao, valor_liquido, status)
    VALUES (NEW.pedido_id, v_lojista_id, v_percentual, v_valor_bruto, v_valor_comissao, v_valor_liquido, 'pendente');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- TRIGGERS

CREATE TRIGGER trg_cancelamento_pedido
AFTER UPDATE ON pedido
FOR EACH ROW
EXECUTE FUNCTION fn_tg_cancelamento_pedido();

CREATE TRIGGER trg_log_pedido
AFTER INSERT OR UPDATE ON pedido
FOR EACH ROW
EXECUTE FUNCTION fn_tg_log_pedido();

CREATE TRIGGER trg_log_transacao
AFTER INSERT OR UPDATE ON transacoes
FOR EACH ROW
EXECUTE FUNCTION fn_tg_log_transacao();

CREATE TRIGGER trg_controle_estoque
AFTER INSERT OR DELETE ON item
FOR EACH ROW
EXECUTE FUNCTION fn_tg_controle_estoque();

CREATE TRIGGER trg_gerar_comissao
AFTER INSERT ON frete
FOR EACH ROW
EXECUTE FUNCTION fn_tg_gerar_comissao();

-- Selects
select * from clientes
select * from endereco
select * from contas
select * from cartoes
select * from lojista
select * from categoria
select * from transportadora
select * from transferencias
select * from transacoes
select * from produto
select * from pedido
select * from item
select * from frete
select * from comissao
select * from estorno
select * from estorno_parcela
select * from auditoria;
select * from log_pedido;
select * from log_saldo;
select * from log_transacao;