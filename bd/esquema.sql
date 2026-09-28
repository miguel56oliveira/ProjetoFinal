-- Tabela Equipa
create table Equipa (
	id_equipa int auto_increment primary key,
    nome varchar(100) not null
);

-- Tabela Jogador
create table Jogador (
	id_jogador int auto_increment primary key,
    nome varchar(100) not null,
    numero_camisola int not null,
    id_equipa int not null,
    foreign key (id_equipa) references Equipa(id_equipa)
);

-- Tabela Jogo
create table Jogo (
	id_jogo int auto_increment primary key,
    estado varchar(50) Default 'Agendado',
    id_equipa_casa int not null,
    id_equipa_fora int not null,
    foreign key (id_equipa_casa) references Equipa(id_equipa),
    foreign key (id_equipa_fora) references Equipa(id_equipa)
);

-- Tabela Evento de Jogo
create table Evento_Jogo (
	id_evento int auto_increment primary key,
    tipo_evento varchar(50) not null,
    timestamp datetime default current_timestamp,
    id_jogo int not null,
    id_jogador int null,
    id_equipa int not null,
    foreign key (id_jogo) references Jogo(id_jogo),
    foreign key (id_jogador) references Jogador(id_jogador),
    foreign key (id_equipa) references Equipa(id_equipa)
);


