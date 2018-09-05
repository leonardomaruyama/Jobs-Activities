CREATE OR REPLACE VIEW V_STATUS_ORDEM_OTIF AS
SELECT A.OBJNR,
       A.STAT,
       SUBSTR(A.LAST_UPDATE, 1, 8) UDATE,
       SUBSTR(A.LAST_UPDATE, 9, 6) UTIME,
       CASE
         WHEN B.INACT = ' '
           THEN 'Concluído'
           ELSE 'Cancelado'
       END ORDEM, B.INACT,
       CASE
         WHEN B.INACT = ' '
           THEN C.STNAME
           ELSE ' '
       END CONCLUIDO
  FROM (SELECT OBJNR, STAT, MAX(UDATE || UTIME + 0) LAST_UPDATE
          FROM SAPR3.JCDS@ZLP
          WHERE SUBSTR(STAT,1,1) = 'E'
               --AND OBJNR = 'OR000000086120'
         GROUP BY OBJNR, STAT) A, -- Busca a última atualização da ordem
       (SELECT OBJNR,
               STAT,
               UDATE,
               UTIME,
               INACT
          FROM SAPR3.JCDS@ZLP
         WHERE SUBSTR(STAT,1,1) = 'E') B, --Busca se a ordem está ativa
               --AND OBJNR = 'OR000000086120'
       (SELECT ESTAT, TXT30 STNAME
          FROM SAPR3.TJ30T@ZLP
         WHERE STSMA = 'Z_PP_001'
           AND SPRAS = 'P') C --Descrição do status da ordem
 WHERE A.OBJNR = B.OBJNR
   AND A.STAT = B.STAT
   AND A.STAT = C.ESTAT
   AND A.LAST_UPDATE >= '20170101'
   AND SUBSTR(A.LAST_UPDATE, 1, 8) = B.UDATE
   AND SUBSTR(A.LAST_UPDATE, 9, 6) = B.UTIME
;
