# Instalando os pacotes necessários
#if(!require(tidyverse)) install.packages("tidyverse"); library(tidyverse)
#if(!require(lubridate)) install.packages("lubridate"); library(lubridate)
#if(!require(foreign)) install.packages("foreign"); library(foreign)
#if(!require(xts)) install.packages("xts"); library(xts)

# Atribuição de dados para consultar a API do InfoDengue
url <- "https://info.dengue.mat.br/api/alertcity?"  
# inserimos o endereço do InfoDengue
geocode <- 4108304  # indicamos código do IBGE de Foz do Iguaçu
disease <- "dengue" # selecionamos a doença
format <- "csv"     # indicamos o formato de arquivo que será baixado
ew_start <- 1       # indicamos o início da semana epidemiológica 
ew_end <- 53        # indicamos o final da semana epidemiológica
ey_start <- 2012    # indicamos o início do ano a ser exportado
ey_end <- 2022      # indicamos o final do ano a ser exportado



# programando o R para ele trazer os dados diretamente da internet
consulta <- paste0(url,
                   "geocode=", geocode,
                   "&disease=", disease,
                   "&format=", format,
                   "&ew_start=", ew_start,
                   "&ew_end=", ew_end,
                   "&ey_start=", ey_start,
                   "&ey_end=", ey_end)

# visualizando o link armazenado no objeto {`consulta`}
consulta


# Armazenando o banco de dados do InfoDengue {consulta} no objeto {dengue_foz} para 
# analisá-lo
dengue_foz <- read_csv(consulta)


# criando o objeto {`foz_ts`}
foz_ts <- xts(
  
  # selecionando a variável com os dados da incidência de dengue
  x = dengue_foz$p_inc100k,
  
  # selecionando a variável que contém as datas correspondentes
  order.by = dengue_foz$data_iniSE)


# Plotando o diagrama de controle
plot(
  # indicando a série temporal
  x = foz_ts,
  
  # colocando o título do gráfico
  main = 'Distribuição da incidência de dengue em Foz do Iguaçu/PR',
  
  # escrevendo o título do eixo y
  ylab = 'Incidência p/ 100.000 hab.'
)


# Analisando as estatísticas básicas do banco de dengue importado
summary(dengue_foz$p_inc100k)


# Plotando gráfico boxplot com incidência por (`~`) ano
boxplot(dengue_foz$p_inc100k ~ year(dengue_foz$data_iniSE),
        ylab = 'Incidência por 100.000 hab.',
        xlab = "Ano de início da semana epidemiológica",
        
        # Inserindo o título do boxplot
        main = "Distribuição da incidência anual de dengue em Foz do Iguaçu-PR 
		entre 2012-2022.")

# Criando linhas de análise a partir dos parâmetros que definimos
abline(
  h = c(300, 200, 70), 
  lty = 2,
  lwd = 2,
  col = c('red', 'orange', 'blue')
)

# Criando o objeto {`nao_epidemic`} com anos não epidêmicos
nao_epidemic <- c(2012, 2013, 2014, 2017, 2018)

# Criando o objeto {`dengue_2022`} com ano de 2022
dengue_2022 <- dengue_foz |>
  
  # Filtrando o ano para 2022
  filter(year(data_iniSE) == 2022) |>
  
  # Criando uma nova coluna chamada 'sem_epi', referente à semana epidemiológica
  mutate(sem_epi = epiweek(data_iniSE))



# Criando o gráfico com o diagrama de controle 
dengue_stat <- dengue_foz |>
  
  # Filtrando os dados da série em que o ano não é epidêmico
  filter(year(data_iniSE) %in% nao_epidemic) |>
  
  # Criando uma nova coluna chamada 'sem_epi', referente à semana epidemiológica
  mutate(sem_epi = epiweek(data_iniSE)) |>
  
  # Agrupando os dados pela semana epidemiológica
  group_by(sem_epi) |>
  
  # Criando medidas-resumo e limites superior e inferior
  summarise(
    n = n(),
    media = mean(p_inc100k, na.rm = TRUE),
    desvio = sd(p_inc100k, na.rm = TRUE) ,
    sup = media + 2 * desvio,
    inf = media - 2 * desvio
  )


# Visualizando a tabela {`dengue_stat`}
head(dengue_stat)


# Definindo a base a ser utilizada
ggplot(data = dengue_stat) +
  
  # Definindo argumentos estéticos com as variáveis usadas em x e em y
  aes(x = sem_epi, y = media) + 
  
  # Adicionando a linha referente à incidência média de dengue.
  # Adicionando uma geometria de linha na cor azul e largura de 1.2 pixel
  geom_line(aes(color = 'cor_media_casos'), size = 1.2) +
  
  # Adicionando uma geometria de linha na cor laranja. Além disso, inserindo
  # um argumento estético para o eixo y que, no caso, é a variável de limite
  # superior
  geom_line(aes(y = sup, color = 'cor_limite'), size = 1.2) +
  
  # Adicionando uma geometria de colunas utilizando a base de dados
  # {`dengue_2022`} e y como a incidência de dengue em 2022. O argumento
  # `fill` refere-se à cor das barras e `alpha` à transparência.
  geom_col(data = dengue_2022,
           aes(y = p_inc100k, fill = 'cor_incidencia'), alpha = 0.4) +
  
  # Arrumando o eixo x, definindo o intervalo de tempo que será utilizado (`breaks`) 
  # uma sequência de semanas epidemiológicas de 1 a 53 
  # o argumento `expand` ajuda nesse processo.
  scale_x_continuous(breaks = 1:53, expand = c(0, 0)) +
  
  # Definindo os títulos dos eixos x e y
  labs(x = 'Semana Epidemiológica',
       y = 'Incidência por 100 mil hab.',
       title = 'Diagrama de controle de dengue em Foz do Iguaçu/PR no ano de 
	   2022.') +
  
  # Definindo o tema do gráfico
  theme_classic() +
  
  # Criando a legenda das linhas
  scale_color_manual(
    name = "",
    values = c('cor_media_casos' = 'darkblue', 'cor_limite' = 'red'),
    labels = c("Incidência média", "Limite superior")
  ) +
  
  # Criando a legenda das barras
  scale_fill_manual(
    name = "",
    values = c('cor_incidencia' = 'deepskyblue'),
    labels = "Incidência de dengue em 2022"
  )







# Definindo a base a ser utilizada
ggplot(data = dengue_stat) +
  
  # Definindo argumentos para as variáveis do eixo x e y do gráfico
  aes(x = sem_epi, y = media) +
  
  # Suavizando a linha referente à incidência média de dengue
  # o argumento `size` para definir largura da linha = 1.2 pixel
  # o argumento `se` = FALSE desabilita o intervalo de confiança
  # e o argumento `span` definindo o valor da suavização
  stat_smooth(
    aes(color = 'cor_incidencia_media'),
    size = 1.2,
    se = FALSE,
    span = 0.2
  ) +
  
  # Suavizando a linha referente ao limite superior
  stat_smooth(
    aes(y = sup, color = 'cor_limite'),
    size = 1.2,
    se = FALSE,
    span = 0.2
  ) +
  
  # Adicionando uma geometria de colunas utilizando a base de dados
  # {`dengue_2022`} e y como a incidência de dengue em 2022.
  geom_col(data = dengue_2022,
           aes(y = p_inc100k, fill = 'cor_incidencia'),
           alpha = 0.4) +
  
  # Arrumando o eixo x, definindo o intervalo de tempo que será utilizado (`breaks`) 
  # uma sequência de semanas epidemiológicas de 1 a 53 
  # o argumento `expand` ajuda nesse processo.
  scale_x_continuous(breaks = 1:53, expand = c(0, 0)) +
  
  # Definindo os títulos dos eixos x, y e também do gráfico
  labs(x = 'Semana Epidemiológica',
       y = 'Incidência por 100 mil hab.',
       title = 'Diagrama de controle de dengue em Foz do Iguaçu/PR no ano 
	   de 2022.') +
  
  # Definindo o tema do gráfico
  theme_classic() +
  
  # Criando a legenda das linhas
  scale_color_manual(
    name = "",
    values = c('cor_incidencia_media' = 'darkblue', 'cor_limite' = 'red'),
    labels = c("Incidência média de casos", "Limite superior")
  ) +
  
  # Criando a legenda das barras
  scale_fill_manual(
    name = "",
    values = c('cor_incidencia' = 'deepskyblue'),
    labels = "Incidência de dengue em 2022"
  )


library(foreign)

# criando objeto do tipo dataframe (tabela) {sinan_hep_sp_2007_2016} com o 
# banco de dados {sinan_hep_sp_2007_2016.dbf}
sinan_hep_sp_2007_2016 <- read.dbf("/home/pamela/Documentos/r-data-science/Dados/sinan_hep_sp_2007_2016.dbf", as.is = TRUE)

# criando objeto do tipo dataframe (tabela) {sinan_hep_sp_fev_2017} com o 
# banco de dados {sinan_hep_sp_fev_2017.dbf}
sinan_hep_sp_fev_2017 <- read.dbf("/home/pamela/Documentos/r-data-science/Dados/sinan_hep_sp_fev_2017.dbf", as.is = TRUE)




# Criando a tabela {`sinan_hep_sp_cont_07_16`}
sinan_hep_sp_cont_07_16 <- sinan_hep_sp_2007_2016 |>
  
  # Utilizando a função `mutate()` para criar as novas colunas
  mutate(
    
    # Criando uma nova coluna chamada 'sem_epi', referente à semana
    # epidemiológica dos primeiros sintomas
    sem_epi = epiweek(x = DT_SIN_PRI),
    
    # Criando uma nova coluna chamada 'ano', referente ao ano dos primeiros sintomas
    ano = year(x = DT_SIN_PRI)) |>
  
  # Contando a frequência de notificações por ano e semana epidemiológica
  count(ano, sem_epi)



head(sinan_hep_sp_cont_07_16)



# Criando o objeto {`sinan_hep_sp_cont_fev17`} e 
# realizando a contagem dos casos segundo a
# semana epidemiológica e ano dos primeiros sintomas

sinan_hep_sp_cont_fev17 <- sinan_hep_sp_fev_2017 |>
  mutate(sem_epi = epiweek(DT_SIN_PRI),
         ano = year(DT_SIN_PRI)) |>
  count(ano, sem_epi)





#Definindo a mediana geral de casos confirmados entre 2007 e 2016
mediana_geral <- median(sinan_hep_sp_cont_07_16$n)


# utilizando a função `boxplot()` para criar o gráfico
boxplot(
  
  # Definindo o cruzamento número de casos por ano
  # Aqui utilizamos o símbolo "~" para sinalizar o cruzamento das variáveis
  sinan_hep_sp_cont_07_16$n ~ sinan_hep_sp_cont_07_16$ano,
  
  # Definindo os títulos dos eixos x e y
  ylab = 'Número de casos confirmados de Hepatite A',
  xlab = 'Ano dos primeiros sintomas',
  
  # Definindo o título do boxplot
  main = 'Número de casos confirmados de Hepatite A em São Paulo/SP entre 2007-2016'
)

# Criando linhas de análise
abline(
  h = mediana_geral,
  lty = 2,
  lwd = 2,
  col = "red"
)



# criando o objeto {nao_epidemic} para armazenar os anos não epidêmicos
nao_epidemic <- c(2008:2013, 2015, 2016)




# Criando o objeto {`hep_stat`}
hep_stat <- sinan_hep_sp_cont_07_16 |>
  
  # Filtrando os anos contidos no grupo de anos não epidêmicos
  filter(ano %in% nao_epidemic) |>
  
  # Agrupando os dados pela semana epidemiológica
  group_by(sem_epi) |>
  
  # Criando medidas-resumo e limites superior e inferior
  summarise(
    media = mean(n, na.rm = TRUE),
    desvio = sd(n, na.rm = TRUE) ,
    sup = media + 2 * desvio,
    inf = media - 2 * desvio
  )





# Criando um novo objeto  {`grafico_base`}
grafico_base <- ggplot(data = hep_stat) +
  
  # Definindo as variáveis usadas no eixo x e em y do gráfico
  aes(x = sem_epi, y = media) +
  
  # Adicionando uma geometria de linha com largura de 1.2 pixel
  # referente ao número médio de casos confirmados. 
  # Além disso, inserindo um argumento estético para a cor, 
  # que será convertida na legenda.
  geom_line(aes(color = "cor_media_casos"), size = 1.2) +
  
  # Adicionando uma geometria de linha referente ao limite superior.
  # Além disso, inserindo um argumento estético para o eixo y e
  # para a cor, que será convertida na legenda.
  geom_line(aes(y = sup, color = 'cor_limite'), size = 1.2) +
  
  # Arrumando o eixo x, definindo o intervalo de tempo que será utilizado (`breaks`) 
  # uma sequência de semanas epidemiológicas de 1 a 53 
  # o argumento `expand` ajuda nesse processo.
  scale_x_continuous(breaks = 1:53, expand = c(0, 0)) +
  
  # Definindo os títulos dos eixos x e y
  labs(x = '',
       y = '',
       title = 'Diagrama de controle') +
  
  # Definindo o tema do gráfico
  theme_classic() +
  
  # Criando a legenda das linhas
  scale_color_manual(
    name = "",
    values = c('cor_media_casos' = 'darkblue', 'cor_limite' = 'red'),
    labels = c("Média de casos confirmados", "Limite superior")
  )

#visualizando o gráfico criado
grafico_base





grafico_base_suavizado <- ggplot(data = hep_stat) +
  
  # Definindo as variáveis usadas no eixo x e em y do gráfico
  aes(x = sem_epi, y = media) +
  
  # Suavizando a linha referente ao número médio de casos.
  # o argumento `size` para definir largura da linha = 1.2 pixel
  # O argumento `se` = FALSE desabilita o intervalo de confiança
  # e o argumento `span` definindo o valor da suavização
  stat_smooth(
    aes(color = 'cor_media_casos'),
    size = 1.2,
    se = FALSE,
    span = 0.2
  ) +
  
  # Suavizando a linha referente ao limite superior
  stat_smooth(
    aes(y = sup, color = 'cor_limite'),
    size = 1.2,
    se = FALSE,
    span = 0.2
  ) +
  
  # Arrumando o eixo x, definindo o intervalo de tempo que será utilizado (`breaks`) 
  # uma sequência de semanas epidemiológicas de 1 a 53 
  # o argumento `expand` ajuda nesse processo.
  scale_x_continuous(breaks = 1:53, expand = c(0, 0)) +
  
  # Definindo os títulos dos eixos x e y
  labs(x = '',
       y = '',
       title = 'Diagrama de controle') +
  
  # Definindo o tema do gráfico
  theme_classic() +
  
  # Criando a legenda das linhas
  scale_color_manual(
    name = "",
    values = c('cor_media_casos' = 'darkblue', 'cor_limite' = 'red'),
    labels = c("Média suavizada de casos confirmados", "Limite superior suavizado")
  )

#visualizando o gráfico criado
grafico_base_suavizado





# Gráfico criado anteriormente
grafico_base_suavizado +
  
  # Adicionando (+) uma geometria de colunas utilizando a base de dados
  # {`sinan_hep_sp_cont_fev17`}
  geom_col(data = sinan_hep_sp_cont_fev17,
           
           # O eixo y é definido como a frequência de casos (n).
           # As barras serão preenchidas com valor textual para definição da 
           # legenda.
           aes(y = n, fill = 'cor_n_casos'), alpha = 0.4) +
  
  # Definindo a legenda das barras, convertendo o valor textual em um nome de cor
  # e definindo o rótulo
  scale_fill_manual(
    name = "",
    values = c('cor_n_casos' = 'deepskyblue'),
    labels = "Número de casos até fev/2017"
  )




# Importando o banco de dados {`sinan_hep_sp_mar_2017.dbf`} para o `R`
sinan_hep_sp_mar_2017 <- read.dbf("/home/pamela/Documentos/r-data-science/Dados/sinan_hep_sp_mar_2017.dbf", as.is = TRUE)


# Criando o objeto {`sinan_hep_sp_cont_mar17`} e 
# realizando a contagem dos casos segundo a
# semana epidemiológica e ano dos primeiros sintomas
sinan_hep_sp_cont_mar17 <- sinan_hep_sp_mar_2017 |>
  mutate(
    sem_epi = epiweek(DT_SIN_PRI),
    ano = year(DT_SIN_PRI)
  ) |>
  count(ano, sem_epi)


# Gráfico criado anteriormente
grafico_base_suavizado +
  
  # Adicionando uma geometria de colunas utilizando a base de dados
  # {`sinan_hep_sp_cont_mar17`}
  geom_col(data = sinan_hep_sp_cont_mar17,
           aes(y = n, fill = 'cor_n_casos'), alpha = 0.4) +
  
  # Definindo a legenda das barras, convertendo o valor textual em um nome de cor
  # e definindo o rótulo
  scale_fill_manual(
    name = "",
    values = c('cor_n_casos' = 'deepskyblue'),
    labels = "Número de casos até março/2017"
  )





# Figura 12: Gráfico do diagrama de controle de Hepatite A, em São Paulo/SP até dezembro de 2017.


# Importando o banco de dados {`sinan_hep_sp_dez_2017.dbf`} para o `R`
sinan_hep_sp_dez_2017<- read.dbf("/home/pamela/Documentos/r-data-science/Dados/sinan_hep_sp_dez_2017.dbf", as.is = TRUE)


sinan_hep_sp_cont_17 <- sinan_hep_sp_dez_2017 |>
  mutate(
    sem_epi = epiweek(DT_SIN_PRI),
    ano = year(DT_SIN_PRI)
  ) |>
  count(ano, sem_epi)


grafico_base_suavizado +
  geom_col(data = sinan_hep_sp_cont_17,
           aes(y = n, fill = 'cor_n_casos'), alpha = 0.4) +
  scale_fill_manual(
    name = "",
    values = c('cor_n_casos' = 'deepskyblue'),
    labels = "Número de casos até dez/2017"
  ) +
  
  ggtitle("Diagrama de controle de Hepatite A em São Paulo/SP entre 2006-2017")
