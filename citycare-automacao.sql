
-- CRIACAO DAS TABELAS --

CREATE TABLE tb_localizacao (
    id_localizacao NUMBER(4) NOT NULL,
    estado         VARCHAR2(2),
    cidade         VARCHAR2(20),
    bairro         VARCHAR2(20),
    logradouro     VARCHAR2(100),
    numero         NUMBER(4),
    CONSTRAINT pk_localizacao PRIMARY KEY ( id_localizacao )
);

CREATE TABLE tb_usuario (
    id_usuario     NUMBER(4) NOT NULL,
    nome           VARCHAR2(20),
    email          VARCHAR2(30),
    telefone       VARCHAR2(20),
    tipo_usuario   VARCHAR2(10),
    id_localizacao NUMBER(4) NOT NULL,
    CONSTRAINT pk_usuario PRIMARY KEY ( id_usuario ),
    CONSTRAINT fk_local_user FOREIGN KEY ( id_localizacao ) REFERENCES tb_localizacao ( id_localizacao )
);



CREATE TABLE tb_monitoramento_ambiental (
    id_monitoramento NUMBER(4) NOT NULL,
    nivel_poluicao   VARCHAR2(10),
    qualidade_ar     VARCHAR2(8),
    dt_medicao       DATE,
    id_localizacao   NUMBER(4) NOT NULL,
    CONSTRAINT pk_monitoramento_ambiental PRIMARY KEY ( id_monitoramento ),
    CONSTRAINT fk_local_monitor FOREIGN KEY ( id_localizacao ) REFERENCES tb_localizacao ( id_localizacao )
);



CREATE TABLE tb_ocorrencia (
    id_ocorrencia     NUMBER(4) NOT NULL,
    tipo_ocorrencia   VARCHAR2(20),
    descricao         VARCHAR2(100),
    dt_ocorrencia     DATE,
    status_ocorrencia VARCHAR2(12),
    dt_resolucao      DATE,
    id_usuario        NUMBER(4) NOT NULL,
    id_localizacao    NUMBER(4) NOT NULL,
    CONSTRAINT pk_ocorrencia PRIMARY KEY ( id_ocorrencia ),
    CONSTRAINT fk_local_ocorrencia FOREIGN KEY ( id_localizacao ) REFERENCES tb_localizacao ( id_localizacao ),
    CONSTRAINT fk_user_ocorrencia FOREIGN KEY ( id_usuario ) REFERENCES tb_usuario ( id_usuario )
);



CREATE TABLE tb_servico_limpeza (
    id_servico     NUMBER(4) NOT NULL,
    tipo_servico   VARCHAR2(30),
    id_localizacao NUMBER(4) NOT NULL,
    dt_servico     DATE,
    CONSTRAINT pk_servico_limpeza PRIMARY KEY ( id_servico ),
    CONSTRAINT fk_local_servico FOREIGN KEY ( id_localizacao ) REFERENCES tb_localizacao ( id_localizacao )
);



CREATE TABLE tb_alerta (
    id_alerta         NUMBER(4) NOT NULL,
    id_usuario        NUMBER(4) NOT NULL,
    id_ocorrencia     NUMBER(4) NOT NULL,
    mensagem          VARCHAR2(255),
    CONSTRAINT pk_alerta PRIMARY KEY (id_alerta),
    CONSTRAINT fk_alerta_usuario FOREIGN KEY (id_usuario) REFERENCES tb_usuario (id_usuario),
    CONSTRAINT fk_alerta_ocorrencia FOREIGN KEY (id_ocorrencia) REFERENCES tb_ocorrencia (id_ocorrencia)
);


CREATE SEQUENCE  seq_id  START WITH 1000 INCREMENT BY 1 MINVALUE 1000 MAXVALUE 9999 CYCLE;

/******************************************************************************************************************************/

-- AUTOMACOES --

-- 1-	CHECAGEM E PREENCHIMENTO DE ENDEREÇO AO INSERIR DADOS EM OUTRAS TABELAS RELACIONADAS:

CREATE OR REPLACE PROCEDURE sp_verificar_ou_registrar_localizacao (
                p_estado IN tb_localizacao.estado%TYPE,
                p_cidade IN tb_localizacao.cidade%TYPE,
                p_bairro IN tb_localizacao.bairro%TYPE,
                p_logradouro IN tb_localizacao.logradouro%TYPE,
                p_numero IN tb_localizacao.numero%TYPE,
                p_id_localizacao OUT tb_localizacao.id_localizacao%TYPE
                )
AS
BEGIN
                SELECT id_localizacao INTO p_id_localizacao
                FROM tb_localizacao
                WHERE estado = p_estado
                AND cidade = p_cidade
                AND bairro = p_bairro
                AND logradouro = p_logradouro
                AND numero = p_numero;
 EXCEPTION
                WHEN NO_DATA_FOUND THEN
                        INSERT INTO tb_localizacao (id_localizacao, estado, cidade, bairro, logradouro, numero)
                        VALUES (seq_id.NEXTVAL, p_estado, p_cidade, p_bairro, p_logradouro, p_numero)
                         RETURNING id_localizacao INTO p_id_localizacao;              
END sp_verificar_ou_registrar_localizacao;
/

CREATE OR REPLACE PROCEDURE sp_inserir_usuario_e_localizacao(
                p_nome           IN tb_usuario.nome%TYPE,
                p_email          IN tb_usuario.email%TYPE,
                p_telefone       IN tb_usuario.telefone%TYPE,
                p_tipo_usuario   IN tb_usuario.tipo_usuario%TYPE,
                p_estado         IN tb_localizacao.estado%TYPE,
                p_cidade         IN tb_localizacao.cidade%TYPE,
                p_bairro         IN tb_localizacao.bairro%TYPE,
                p_logradouro     IN tb_localizacao.logradouro%TYPE,
                p_numero         IN tb_localizacao.numero%TYPE
)       AS
                v_id_localizacao    NUMBER;
BEGIN
                sp_verificar_ou_registrar_localizacao(
                        p_estado => p_estado,
                        p_cidade => p_cidade,
                        p_bairro => p_bairro,
                        p_logradouro => p_logradouro,
                        p_numero => p_numero,
                        p_id_localizacao => v_id_localizacao
                );
                
                INSERT INTO tb_usuario (id_usuario, nome, email, telefone, tipo_usuario, id_localizacao)
                VALUES (seq_id.NEXTVAL, p_nome, p_email, p_telefone, p_tipo_usuario, v_id_localizacao);
    
                COMMIT;
                EXCEPTION
                        WHEN OTHERS THEN
                        ROLLBACK;
                        RAISE_APPLICATION_ERROR(-20001, 'Erro ao inserir usuário: ' || SQLERRM);
END sp_inserir_usuario_e_localizacao;
/



CREATE OR REPLACE PROCEDURE sp_inserir_ocorrencia_e_localizacao(
                p_tipo_ocorrencia           IN tb_ocorrencia.tipo_ocorrencia%TYPE,
                p_descricao          IN tb_ocorrencia.descricao%TYPE,
                p_nome           IN tb_usuario.nome%TYPE,
                p_email         IN tb_usuario.email%TYPE,
                p_estado         IN tb_localizacao.estado%TYPE,
                p_cidade         IN tb_localizacao.cidade%TYPE,
                p_bairro         IN tb_localizacao.bairro%TYPE,
                p_logradouro     IN tb_localizacao.logradouro%TYPE,
                p_numero         IN tb_localizacao.numero%TYPE
)       AS
                v_id_localizacao    NUMBER;
                v_id_usuario         NUMBER;
BEGIN
                sp_verificar_ou_registrar_localizacao(
                        p_estado => p_estado,
                        p_cidade => p_cidade,
                        p_bairro => p_bairro,
                        p_logradouro => p_logradouro,
                        p_numero => p_numero,
                        p_id_localizacao => v_id_localizacao
                );
                
                BEGIN
                        SELECT id_usuario INTO v_id_usuario
                        FROM tb_usuario
                        WHERE nome = p_nome
                        AND email = p_email
                        AND ROWNUM = 1;
                 EXCEPTION
                        WHEN NO_DATA_FOUND THEN
                        RAISE_APPLICATION_ERROR(-20002, 'Usuário não encontrado.');
                END;
                
                INSERT INTO tb_ocorrencia (id_ocorrencia, tipo_ocorrencia, descricao, dt_ocorrencia, status_ocorrencia, id_usuario, id_localizacao)
                VALUES (seq_id.NEXTVAL, p_tipo_ocorrencia, p_descricao, SYSDATE, 'Em Andamento', v_id_usuario, v_id_localizacao);
    
                COMMIT;
                EXCEPTION
                        WHEN OTHERS THEN
                        ROLLBACK;
                        RAISE_APPLICATION_ERROR(-20003, 'Erro ao inserir ocorrência: ' || SQLERRM);
END sp_inserir_ocorrencia_e_localizacao;
/



CREATE OR REPLACE PROCEDURE sp_inserir_monitoramento_e_localizacao(
                p_nivel_poluicao           IN tb_monitoramento_ambiental.nivel_poluicao%TYPE,
                p_qualidade_ar         IN tb_monitoramento_ambiental.qualidade_ar%TYPE,
                p_dt_medicao       IN tb_monitoramento_ambiental.dt_medicao%TYPE,
                p_estado         IN tb_localizacao.estado%TYPE,
                p_cidade         IN tb_localizacao.cidade%TYPE,
                p_bairro         IN tb_localizacao.bairro%TYPE,
                p_logradouro     IN tb_localizacao.logradouro%TYPE,
                p_numero         IN tb_localizacao.numero%TYPE
)       AS
                v_id_localizacao    NUMBER;
BEGIN
                sp_verificar_ou_registrar_localizacao(
                        p_estado => p_estado,
                        p_cidade => p_cidade,
                        p_bairro => p_bairro,
                        p_logradouro => p_logradouro,
                        p_numero => p_numero,
                        p_id_localizacao => v_id_localizacao
                );
                
                INSERT INTO tb_monitoramento_ambiental (id_monitoramento, nivel_poluicao, qualidade_ar, dt_medicao, id_localizacao)
                VALUES (seq_id.NEXTVAL, p_nivel_poluicao, p_qualidade_ar, p_dt_medicao, v_id_localizacao);
    
                COMMIT;
                EXCEPTION
                        WHEN OTHERS THEN
                        ROLLBACK;
                        RAISE_APPLICATION_ERROR(-20004, 'Erro ao inserir medição ambiental: ' || SQLERRM);
END sp_inserir_monitoramento_e_localizacao;
/




CREATE OR REPLACE PROCEDURE sp_inserir_servico_limpeza_e_localizacao(
                p_tipo_servico           IN tb_servico_limpeza.tipo_servico%TYPE,
                p_dt_servico         IN tb_servico_limpeza.dt_servico%TYPE,
                p_estado         IN tb_localizacao.estado%TYPE,
                p_cidade         IN tb_localizacao.cidade%TYPE,
                p_bairro         IN tb_localizacao.bairro%TYPE,
                p_logradouro     IN tb_localizacao.logradouro%TYPE,
                p_numero         IN tb_localizacao.numero%TYPE
)       AS
                v_id_localizacao    NUMBER;
BEGIN
                sp_verificar_ou_registrar_localizacao(
                        p_estado => p_estado,
                        p_cidade => p_cidade,
                        p_bairro => p_bairro,
                        p_logradouro => p_logradouro,
                        p_numero => p_numero,
                        p_id_localizacao => v_id_localizacao
                );
                
                INSERT INTO tb_servico_limpeza (id_servico, tipo_servico, dt_servico, id_localizacao)
                VALUES (seq_id.NEXTVAL, p_tipo_servico, p_dt_servico, v_id_localizacao);
    
                COMMIT;
                EXCEPTION
                        WHEN OTHERS THEN
                        ROLLBACK;
                        RAISE_APPLICATION_ERROR(-20005, 'Erro ao inserir serviço de limpeza: ' || SQLERRM);
END sp_inserir_servico_limpeza_e_localizacao;
/


/******************************************************************************************************************************/

-- 2-	ALERTAS ENVIADOS PARA TODOS OS USUÁRIOS QUE MORAM NO MESMO BAIRRO ONDE HOUVER UM NOVO REGISTRO OU UMA ATUALIZAÇÃO DE UMA OCORRÊNCIA:

CREATE OR REPLACE TRIGGER tr_alerta_ocorrencia
AFTER INSERT OR UPDATE ON tb_ocorrencia
FOR EACH ROW
DECLARE
                v_bairro VARCHAR2(20);
BEGIN
   
                SELECT bairro INTO v_bairro
                FROM tb_localizacao
                WHERE id_localizacao = :NEW.id_localizacao;

    
                INSERT INTO tb_alerta (id_alerta, id_usuario, id_ocorrencia, mensagem)
                SELECT seq_id.NEXTVAL, u.id_usuario, :NEW.id_ocorrencia, 'Nova ocorrência em ' || v_bairro
                FROM tb_usuario u
                JOIN tb_localizacao l ON u.id_localizacao = l.id_localizacao
                WHERE l.bairro = v_bairro;
END;
/


/******************************************************************************************************************************/

-- 3-	SOMENTE O USUÁRIO QUE REGISTROU O PROBLEMA OU ADMIN PODE ATUALIZAR O STATUS DA OCORRÊNCIA:

CREATE OR REPLACE TRIGGER tr_verificar_permissao_atualizacao
BEFORE UPDATE OF status_ocorrencia ON tb_ocorrencia
FOR EACH ROW
DECLARE
  v_tipo_usuario VARCHAR2(10);
BEGIN

  SELECT tipo_usuario
    INTO v_tipo_usuario
    FROM tb_usuario
   WHERE id_usuario = :NEW.id_usuario;


  IF :NEW.id_usuario <> :OLD.id_usuario AND v_tipo_usuario <> 'Admin' THEN
    RAISE_APPLICATION_ERROR(-20006, 'Somente o criador ou um administrador pode atualizar o status da ocorrência.'  || SQLERRM);
  END IF;
END;
/


/******************************************************************************************************************************/

-- 4-	NOTIFICAÇÕES PARA USUÁRIOS INFORMANDO O DIA DA COLETA DE LIXO EM SEUS BAIRROS:

CREATE OR REPLACE TRIGGER tr_notifica_coleta_lixo
AFTER INSERT ON tb_servico_limpeza
FOR EACH ROW
    DECLARE
                v_bairro VARCHAR2(20);
BEGIN
   
                SELECT bairro INTO v_bairro
                FROM tb_localizacao
                WHERE id_localizacao = :NEW.id_localizacao;

    
                INSERT INTO tb_alerta (id_alerta, id_usuario, id_ocorrencia, mensagem)
                SELECT seq_id.NEXTVAL, u.id_usuario, 9999,'Coleta de lixo agendada para hoje em ' || v_bairro
                FROM tb_usuario u
                JOIN tb_localizacao l ON u.id_localizacao = l.id_localizacao
                WHERE l.bairro = v_bairro;  
     
END;
/




