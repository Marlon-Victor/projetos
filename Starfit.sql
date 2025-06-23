create database if not exists starfit;
use starfit;

create table usuarios (
  id_usuario int auto_increment primary key,
  nome varchar(70) not null,
  email varchar(50) not null unique,
  senha varchar(100) not null,
  tipo_usuario enum('aluno', 'instrutor', 'administrador') not null,
  ativo boolean default true
);

create table alunos (
  id_aluno int auto_increment primary key,
  id_usuario int not null,
  peso decimal(5,2) check (peso > 0),
  altura decimal(4,2) check (altura > 0),
  objetivo text,
  data_nascimento date,
  ativo boolean default true,
  foreign key (id_usuario) references usuarios(id_usuario)
);

create table instrutores (
  id_instrutor int auto_increment primary key,
  id_usuario int not null,
  especialidade varchar(70),
  ativo boolean default true,
  foreign key (id_usuario) references usuarios(id_usuario)
);

create table treinos (
  id_treino int auto_increment primary key,
  id_aluno int not null,
  data_treino date not null,
  tipo_treino enum('musculação', 'cardio', 'alongamento', 'outro') not null,
  foreign key (id_aluno) references alunos(id_aluno)
);

create table exercicios (
  id_exercicio int auto_increment primary key,
  nome varchar(50) not null,
  descricao text
);

create table exercicios_treino (
  id_treino int not null,
  id_exercicio int not null,
  repeticões int check (repeticões >= 0),
  series int check (series >= 0),
  peso decimal(5,2) check (peso >= 0),
  primary key (id_treino, id_exercicio),
  foreign key (id_treino) references treinos(id_treino),
  foreign key (id_exercicio) references exercicios(id_exercicio)
);

create table metas (
  id_meta int auto_increment primary key,
  id_aluno int not null,
  tipo_meta enum('aumento de carga', 'redução de peso', 'melhora de tempo', 'outro') not null,
  valor_meta decimal(5,2) not null,
  data_inicio date not null,
  data_fim date not null,
  foreign key(id_aluno) references alunos(id_aluno)
);

create table planos_treino (
  id_plano int auto_increment primary key,
  id_instrutor int not null,
  nome_plano varchar(60),
  descricao text,
  foreign key (id_instrutor) references instrutores(id_instrutor)
);

create table plano_exercicios (
  id_plano int not null,
  id_exercicio int not null,
  series int check (series >= 0),
  repeticões int check (repeticões >= 0),
  peso decimal(5,2) check (peso >= 0),
  primary key (id_plano, id_exercicio),
  foreign key(id_plano) references planos_treino(id_plano),
  foreign key (id_exercicio) references exercicios(id_exercicio)
);

create table aulas (
  id_aula int auto_increment primary key,
  id_instrutor int not null,
  nome_aula varchar(50) not null,
  descricao text,  
  horario datetime not null,
  foreign key (id_instrutor) references instrutores(id_instrutor)
);

create table agendamentos_aulas (
  id_agendamento int auto_increment primary key,
  id_aluno int not null,
  id_aula int not null,
  data_agendamento datetime not null,
  status enum('confirmado', 'cancelado', 'pendente') not null,
  foreign key (id_aluno) references alunos(id_aluno),
  foreign key (id_aula) references aulas(id_aula)
);

create table feedback_instrutor (
  id_feedback int auto_increment primary key,
  id_instrutor int not null,
  id_aluno int not null,
  feedback text,
  data_feedback date not null,
  foreign key (id_instrutor) references instrutores(id_instrutor),
  foreign key (id_aluno) references alunos(id_aluno)
);

create table historico_treino (
  id_hist_treino int auto_increment primary key,  
  id_treino int not null,
  data_treino date not null,
  feedback text,
  foreign key (id_treino) references treinos(id_treino)
);

create table login (
  id_login int auto_increment primary key, 
  id_usuario int not null,
  username varchar(50) not null unique,
  password varchar(100) not null,
  foreign key (id_usuario) references usuarios(id_usuario)
);

create table log_usuarios (
  id_log int auto_increment primary key, 
  id_usuario int, 
  acao varchar(10), 
  data_acao datetime
);

create table log_alunos (
  id_log int auto_increment primary key, 
  id_aluno int, 
  acao varchar(10), 
  data_acao datetime
);

create table log_instrutores (
  id_log int auto_increment primary key, 
  id_instrutor int, 
  acao varchar(10), 
  data_acao datetime
);

create view alunos_ativos as
select u.id_usuario, u.nome, u.email, a.id_aluno, a.peso, a.altura, a.objetivo
from usuarios u
join alunos a on u.id_usuario = a.id_usuario
where u.ativo = true and a.ativo = true;

create view historico_treinos_aluno as
select t.id_treino, a.id_aluno, u.nome as nome_aluno, t.data_treino, t.tipo_treino, ht.feedback as feedback_treino
from treinos t 
join alunos a on t.id_aluno = a.id_aluno 
join usuarios u on a.id_usuario = u.id_usuario
left join historico_treino ht on t.id_treino = ht.id_treino
order by t.data_treino desc;

create view alunos_metas_ativas as
select m.id_meta, a.id_aluno, u.nome as nome_aluno, m.tipo_meta, m.valor_meta, m.data_inicio, m.data_fim
from metas m
join alunos a on m.id_aluno = a.id_aluno
join usuarios u on a.id_usuario = u.id_usuario
where current_date() between m.data_inicio and m.data_fim;

create view aulas_agendadas as
select ag.id_agendamento, u.nome as aluno, au.nome_aula, ag.data_agendamento, ag.status
from agendamentos_aulas ag
join aulas au on ag.id_aula = au.id_aula
join alunos al on ag.id_aluno = al.id_aluno
join usuarios u on al.id_usuario = u.id_usuario;

delimiter //

create procedure inserir_aluno (
  in p_id_usuario int,
  in p_peso decimal(5,2),
  in p_altura decimal(4,2),
  in p_objetivo text,
  in p_data_nascimento date
)
begin
  insert into alunos (id_usuario, peso, altura, objetivo, data_nascimento)
  values (p_id_usuario, p_peso, p_altura, p_objetivo, p_data_nascimento);
end;
//

create procedure inserir_treino (
  in p_id_aluno int,
  in p_data_treino date,
  in p_tipo_treino enum('musculação','cardio','alongamento','outro')
)
begin
  insert into treinos (id_aluno, data_treino, tipo_treino)
  values (p_id_aluno, p_data_treino, p_tipo_treino);
end;
//

create procedure consultar_treinos (
  in p_id_aluno int
)
begin
  select * from treinos
  where id_aluno = p_id_aluno;
end;
//

create function calcular_imc(p_id_aluno int)
returns decimal(5,2)
deterministic
begin
  declare v_peso decimal(5,2);
  declare v_altura decimal(4,2);
  declare v_imc decimal(5,2);

  select peso, altura into v_peso, v_altura
  from alunos
  where id_aluno = p_id_aluno;

  if v_altura > 0 then
    set v_imc = v_peso / (v_altura * v_altura);
  else
    set v_imc = null;
  end if;

  return v_imc;
end;
//

create function total_treinos_aluno(p_id_aluno int)
returns int
deterministic
begin
  declare v_total int;

  select count(*) into v_total
  from treinos
  where id_aluno = p_id_aluno;

  return v_total;
end;
//

create function total_aulas_agendadas(p_id_aluno int)
returns int
deterministic
begin
  declare v_total int;

  select count(*) into v_total
  from agendamentos_aulas
  where id_aluno = p_id_aluno
    and status = 'confirmado';

  return v_total;
end;
//

create function media_peso_treino(p_id_treino int)
returns decimal(5,2)
deterministic
begin
  declare v_media decimal(5,2);

  select avg(peso) into v_media
  from exercicios_treino
  where id_treino = p_id_treino;

  return v_media;
end;
//

create function ultimo_feedback(p_id_instrutor int, p_id_aluno int)
returns text
deterministic
begin
  declare v_feedback text;

  select feedback into v_feedback
  from feedback_instrutor
  where id_instrutor = p_id_instrutor
    and id_aluno = p_id_aluno
  order by data_feedback desc
  limit 1;

  return v_feedback;
end;
//

delimiter ;

delimiter //

create trigger after_insert_usuario after insert on usuarios
for each row begin
  insert into log_usuarios (id_usuario, acao, data_acao)
  values (new.id_usuario, 'inserção', now());
end;
//

create trigger after_update_usuario after update on usuarios
for each row begin
  insert into log_usuarios (id_usuario, acao, data_acao)
  values (new.id_usuario, 'update', now());
end;
//

create trigger after_delete_usuario after delete on usuarios
for each row begin
  insert into log_usuarios (id_usuario, acao, data_acao)
  values (old.id_usuario, 'delete', now());
end;
//

create trigger after_insert_aluno after insert on alunos
for each row begin
  insert into log_alunos (id_aluno, acao, data_acao)
  values (new.id_aluno, 'inserção', now());
end;
//

create trigger after_update_aluno after update on alunos
for each row begin
  insert into log_alunos (id_aluno, acao, data_acao)
  values (new.id_aluno, 'update', now());
end;
//

create trigger after_delete_aluno after delete on alunos
for each row begin
  insert into log_alunos (id_aluno, acao, data_acao)
  values (old.id_aluno, 'delete', now());
end;
//

create trigger after_insert_instrutor after insert on instrutores
for each row begin
  insert into log_instrutores (id_instrutor, acao, data_acao)
  values (new.id_instrutor, 'inserção', now());
end;
//

create trigger after_update_instrutor after update on instrutores
for each row begin
  insert into log_instrutores (id_instrutor, acao, data_acao)
  values (new.id_instrutor, 'update', now());
end;
//

create trigger after_delete_instrutor after delete on instrutores
for each row begin
  insert into log_instrutores (id_instrutor, acao, data_acao)
  values (old.id_instrutor, 'delete', now());
end;
//

delimiter // 

create trigger before_insert_usuarios before insert on usuarios 
for each row begin 
	set new.senha = sha2(new.senha, 256);
    end;
 //   

create trigger before_insert_login before insert on login
for each row begin 
	set new.password = sha2(new.password, 256);
    end;

delimiter ;

insert into usuarios (nome, email, senha, tipo_usuario, ativo) values
('Lucas Martins', 'lucas@email.com', 'senha123', 'aluno', true),
('Beatriz Rocha', 'beatriz@email.com', 'senha123', 'aluno', true),
('Carlos Mendes', 'carlos@email.com', 'senha123', 'instrutor', true),
('Juliana Silva', 'juliana@email.com', 'senha123', 'instrutor', true),
('Ana Clara', 'ana@email.com', 'senha123', 'aluno', true),
('Rafael Souza', 'rafael@email.com', 'senha123', 'instrutor', true);

insert into alunos (id_usuario, peso, altura, objetivo, data_nascimento, ativo) values
(1, 80.0, 1.80, 'Ganhar massa muscular', '1995-01-20', true),
(2, 65.5, 1.65, 'Perder peso e definir', '1998-08-15', true),
(5, 72.0, 1.70, 'Melhorar condicionamento físico', '2000-03-10', true);

insert into instrutores (id_usuario, especialidade, ativo) values
(3, 'Musculação', true),
(4, 'Cardio e Funcional', true),
(6, 'Crossfit', true);

insert into treinos (id_aluno, data_treino, tipo_treino) values
(1, '2024-05-15', 'musculação'),
(1, '2024-05-18', 'cardio'),
(2, '2024-05-16', 'musculação'),
(3, '2024-05-20', 'alongamento');

insert into exercicios (nome, descricao) values
('Supino Reto', 'Exercício de peito com barra'),
('Agachamento Livre', 'Exercício para pernas e glúteos'),
('Esteira', 'Exercício aeróbico'),
('Abdominal Supra', 'Exercício para abdômen');

insert into metas (id_aluno, tipo_meta, valor_meta, data_inicio, data_fim) values
(1, 'aumento de carga', 70.00, '2024-05-01', '2024-08-01'),
(2, 'redução de peso', 60.00, '2024-05-01', '2024-07-01'),
(3, 'melhora de tempo', 50.00, '2024-06-01', '2024-09-01');

insert into aulas (id_instrutor, nome_aula, descricao, horario) values
(1, 'Funcional', 'Aula de treino funcional', '2024-06-15 08:00:00'),
(3, 'Crossfit', 'Aula intensa de crossfit', '2024-06-16 10:00:00');

insert into agendamentos_aulas (id_aluno, id_aula, data_agendamento, status) values
(1, 1, '2024-06-10 10:00:00', 'confirmado'),
(2, 2, '2024-06-12 14:00:00', 'pendente');

insert into feedback_instrutor (id_instrutor, id_aluno, feedback, data_feedback) values
(1, 1, 'Ótima dedicação, continue assim!', '2024-06-15'),
(3, 2, 'Precisa melhorar na execução dos movimentos.', '2024-06-16');

insert into login (id_usuario, username, password) values
(1, 'Pedrosm', 'senha123'),
(2, 'beatrizr', 'senha123'),
(3, 'carlosm', 'senha123'),
(4, 'julianas', 'senha123'),
(5, 'anac', 'senha123'),
(6, 'rafaels', 'senha123');

select * from alunos_ativos;
select * from historico_treinos_aluno;
select * from alunos_metas_ativas;
select * from aulas_agendadas;