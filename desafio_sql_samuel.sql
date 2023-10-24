--Desafio Alex

select mes, mercado, SUM(volume) as volume_total
from (
	select TO_CHAR(pod.dat_ini, 'YYYY-MM') as mes, mcd.des_mcd as mercado, fto.vlr_vol as volume
  	from edw.fto_vnd_dia fto 
	join edw.dim_pod pod on fto.srk_pod_ctb = pod.srk_pod
    join edw.dim_mcd mcd on fto.srk_mcd = mcd.srk_mcd
	where mes >= '2023-04'	 
) 
group by mes, mercado order by mes, mercado; 

--1. Qual o histórico de volume faturado por família S&OP por mercado desde a safra 20/21?

select mes, mercado, SUM(volume) as volume_total, S_OP
from (
	select TO_CHAR(pod.dat_ini, 'YYYY-MM') as mes, mcd.des_mcd as mercado, fto.vlr_vol as volume, dia.des_grp_mer  as S_OP
  	from edw.fto_vnd_dia fto 
	join edw.dim_pod pod on fto.srk_pod_ctb = pod.srk_pod
    join edw.dim_mcd mcd on fto.srk_mcd = mcd.srk_mcd
    join edw.fto_tpo_rtn_dia dia on fto.srk_mcd = dia.srk_mcd
	where mes >= '2020-04' and mes <= '2021-03'	 
) 
group by mes, mercado, S_OP order by mes;

--2. Quais são os top 5 clientes em volume faturado no mercado interno na safra 22/23, e qual é o volume?

select cliente, SUM(volume) as volume_total
from (
	select fto.vlr_vol as volume, cli.des_nom_cli as cliente
  	from edw.fto_vnd_dia fto 
	join edw.dim_pod pod on fto.srk_pod_ctb = pod.srk_pod
    join edw.dim_mcd mcd on fto.srk_mcd = mcd.srk_mcd
    join edw.dim_cli cli on cli.srk_cli = fto.srk_cli 
	where TO_CHAR(pod.dat_ini, 'YYYY-MM') >= '2023-04' and mcd.des_mcd  <> 'EXPORTAÇÃO'
) 
group by cliente order by volume_total desc limit 5;

--3. Qual a variação de volume faturado B2B YTD 23/24 vs 22/23?

with vinte as (
	select SUM(volume) as volume_total
	from (
		select TO_CHAR(pod.dat_ini, 'YYYY-MM') as mes, mcd.des_mcd as mercado, fto.vlr_vol as volume, mcd.cod_mcd as S_OP
	  	from edw.fto_vnd_dia fto 
		join edw.dim_pod pod on fto.srk_pod_ctb = pod.srk_pod
	    join edw.dim_mcd mcd on fto.srk_mcd = mcd.srk_mcd
		where mes >= '2022-04' and mes <= '2023-03'	 and S_OP = 'B2B'
	)
	group by S_OP
), vinte_quatro as (
	select SUM(volume) as volume_total
	from (
		select TO_CHAR(pod.dat_ini, 'YYYY-MM') as mes, mcd.des_mcd as mercado, fto.vlr_vol as volume, mcd.cod_mcd as S_OP
	  	from edw.fto_vnd_dia fto 
		join edw.dim_pod pod on fto.srk_pod_ctb = pod.srk_pod
	    join edw.dim_mcd mcd on fto.srk_mcd = mcd.srk_mcd
		where mes >= '2023-04' and mes <= '2024-03'	 and S_OP = 'B2B'
	)
	group by S_OP
)

select v.volume_total as vinte_dois_vinte_tres, q.volume_total as vinte_quatro, vinte_dois_vinte_tres - vinte_quatro as diff
from vinte_quatro q, vinte v


--4. Qual a variação de volume faturado B2B YTD 23/24 vs 22/23 nos top 5 clientes? O que isso significa?
with vinte as (
	select SUM(volume) as volume_total, cliente
	from (
		select TO_CHAR(pod.dat_ini, 'YYYY-MM') as mes, mcd.des_mcd as mercado, fto.vlr_vol as volume, mcd.cod_mcd as S_OP,  cli.des_nom_cli as cliente
	  	from edw.fto_vnd_dia fto 
		join edw.dim_pod pod on fto.srk_pod_ctb = pod.srk_pod
	    join edw.dim_mcd mcd on fto.srk_mcd = mcd.srk_mcd
	    join edw.dim_cli cli on cli.srk_cli = fto.srk_cli 
		where mes >= '2022-04' and mes <= '2023-03'	 and S_OP = 'B2B'
	)
	group by cliente 
), vinte_quatro as (
	select SUM(volume) as volume_total, cliente
	from (
		select TO_CHAR(pod.dat_ini, 'YYYY-MM') as mes, mcd.des_mcd as mercado, fto.vlr_vol as volume, mcd.cod_mcd as S_OP, cli.des_nom_cli as cliente
	  	from edw.fto_vnd_dia fto 
		join edw.dim_pod pod on fto.srk_pod_ctb = pod.srk_pod
	    join edw.dim_mcd mcd on fto.srk_mcd = mcd.srk_mcd
	    join edw.dim_cli cli on cli.srk_cli = fto.srk_cli 
		where mes >= '2023-04' and mes <= '2024-03'	 and S_OP = 'B2B'
	)
	group by cliente
)

select
	top 5 q.cliente as cliente,
	q.volume_total as vinte_dois,
	v.volume_total as vinte_quatro,
	vinte_dois - vinte_quatro as diff
from
	vinte_quatro q
join vinte v on
	q.cliente = v.cliente
order by
	vinte_dois desc


--5. Qual é o histórico da mediana de prêmio PVU vs NY mensal nas últimas 4 safras no B2B?

select
	TO_CHAR(pod.dat_ini,
	'MM-YYYY') as mes ,
	idx.des_idx nyy,
	sum(fto.vlr_pco_brt) / 2 as valor
	
from
	edw.fto_vnd_dia fto
join edw.dim_pod pod on
	fto.srk_pod_ctb = pod.srk_pod
join edw.dim_mcd mcd on
	fto.srk_mcd = mcd.srk_mcd
join edw.dim_idx idx on idx.srk_idx = fto.srk_idx_fat  
where
	mes >= '05-2023'
	and mcd.cod_mcd = 'B2B'
group by
	mes, nyy
order by mes

--6. Qual é a diferença entre indexadores dessa mediana de prêmio PVU vs NY?




--7. Qual é o prêmio médio (vs NY e vs Esalq) B2B aprovado no último ciclo S&OP?


--8. Qual é o prêmio vs Esalq dos volumes B2B spot aprovados no último ciclo S&OP?


--9. Qual é a média de cada quartil de prêmio vs Esalq de Cristal B2B aprovados no último ciclo S&OP?


--10. Qual é o cliente que historicamente mais performa contra a exportação no Varejo?


--11. Quais redes possuem apenas guarani + 1 marca na gondola de amorfo. E quais redes tem algum PDV que seguem a mesma regra? Quantos PDVs?



