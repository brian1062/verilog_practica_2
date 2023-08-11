import numpy as np
from tool._fixedInt import *
import matplotlib.pyplot as plt

from myfunc import rcosine, resp_freq, eyediagram



##Program
## Parametros generales
T     = 1.0/100.0e6 # Periodo de baudio 100MHZ
os    = 4
## Parametros de la respuesta en frecuencia
Nfreqs = 256          # Cantidad de frecuencias

## Parametros del filtro de caida cosenoidal
roll_off   = 0.5 # Roll-Off
Nbauds = 6     # Cantidad de baudios del filtro
## Parametros funcionales
Ts = T/os              # Frecuencia de muestreo

Nsymb=1000
NB=9 ##8,7 queda media fea la resp en frec
NBF=8
round_mode='round'

##FILTRO COSENO REALZADO punto fijo
(t,coseno_realsado) = rcosine(roll_off, T,os,Nbauds,Norm=False)
coseno_r_FixPoint = arrayFixedInt(NB, NBF, coseno_realsado, signedMode='S', roundMode=round_mode, saturateMode='saturate')
#coseno_r_arr = np.zeros(len(coseno_r_FixPoint))
#for ptr in range(len(coseno_r_arr)):
#    coseno_r_arr[ptr]=coseno_r_FixPoint[ptr].fValue

#coseno_r_arr_invert= np.flip(coseno_r_arr) #La invierto para la convolucion "creo que es alpedo pq es lo mismo en el cos realzado"


#ind_i,ind_q=0
prbs9_i = [1,1,0,1,0,1,0,1,0] #SEEDS= I (9’h1AA) 
prbs9_q = [1,1,1,1,1,1,1,1,0] #SEEDS= Q (9’h1FE).
symbolsI= []
symbolsQ= []
symbolsI_Filtred= []
symbolsQ_Filtred= []

#->simula ciclo de reloj
for i in range(Nsymb):#len(prbs9_i)):
    ##PRBS9 para I
    bit_i = prbs9_i[4] ^ prbs9_i[8]  ##XOR bit 5 y 9
    bit_q = prbs9_q[4] ^ prbs9_q[8]

    bit_i_fixed = DeFixedInt(NB,NBF,'S',round_mode,'saturate')
    bit_q_fixed = DeFixedInt(NB,NBF,'S',round_mode,'saturate')
    ##Cambiamos el 0 por -1
    if(prbs9_i[8]==0):
        bit_i_fixed.value=-1.0 
        symbolsI.append(bit_i_fixed) 
    else:
        bit_i_fixed.value=1.0
        symbolsI.append(bit_i_fixed)
    if(prbs9_q[8]==0):
        bit_q_fixed.value=-1.0
        symbolsQ.append(bit_q_fixed)
    else:
        bit_q_fixed.value=1.0
        symbolsQ.append(bit_q_fixed)
    
    #for a in range(os):##UPSAMPLEO No se necesita
    #    symbolsI.append(0)
    prbs9_i.pop() ##Saco el ultimo elemento
    prbs9_q.pop()
    prbs9_i.insert(0,bit_i) ##agrego el resultado de la xor al inicio
    prbs9_q.insert(0,bit_q)
    #simbol_fixed = DeFixedInt(NB+NB,NBF+NBF,'S',round_mode,'saturate') Esto lo hace solo la fixed poin #simbol_fixed.assign()
    #Y[i]= x[i]*h[0] siempre el primer valor
    symbolsI_Filtred.append(symbolsI[i] * coseno_r_FixPoint[0])
    symbolsQ_Filtred.append(symbolsQ[i] * coseno_r_FixPoint[0])


    ##Logica filtro polifasico para simbolos I
    flag = i 
    hvalue=os
    while(flag>=os):
        #if(flag_i>=os):
        symbolsI_Filtred[i] = (symbolsI[flag-os]*coseno_r_FixPoint[hvalue])+symbolsI_Filtred[i]
        flag-=os
        hvalue+=os
        #else:break
        if(hvalue >(os*Nbauds)):break

    ##Logica filtro polifasico para simbolos Q
    flag = i 
    hvalue=os
    while(flag>=os):
        symbolsQ_Filtred[i] = (symbolsQ[flag-os]*coseno_r_FixPoint[hvalue])+symbolsQ_Filtred[i]
        flag-=os
        hvalue+=os
        if(hvalue >(os*Nbauds)):break

print(coseno_r_FixPoint)
#print(len(symbolsI_Filtred))
#print(symbolsI_Filtred)
#print(len(symbolsQ_Filtred))
#print(symbolsQ_Filtred)





###GRAFICOS
### Generacion de las graficas respuesta al impulso
coseno_r_arr = np.zeros(len(coseno_r_FixPoint)) ###se hace esto para sacar los datos del rcoseno_fixpoint
for ptr in range(len(coseno_r_arr)):
    coseno_r_arr[ptr]=coseno_r_FixPoint[ptr].fValue


plt.figure(figsize=[14,7])
plt.suptitle("Respuesta al impulso y en frecuencia")
plt.subplot(2,1,1)
plt.plot(t,coseno_r_arr,'gs-',linewidth=2.0,label=r'$\beta=0.5$')
plt.legend()
plt.grid(True)
plt.xlabel('Muestras')
plt.ylabel('Magnitud')


##grafico de respuesta en frecuencia
[H1,A1,F1] = resp_freq(coseno_r_arr, Ts, Nfreqs)

plt.subplot(2,1,2)
plt.semilogx(F1, 20*np.log10(H1),'g', linewidth=2.0, label=r'$\beta=0.5$')
    
plt.axvline(x=(1./Ts)/2.,color='k',linewidth=2.0)
plt.axvline(x=(1./T)/2.,color='k',linewidth=2.0)
plt.axhline(y=20*np.log10(0.5),color='k',linewidth=2.0)
plt.legend(loc=3)
plt.grid(True)
plt.xlim(F1[1],F1[len(F1)-1])
plt.xlabel('Frequencia [Hz]')
plt.ylabel('Magnitud [dB]')
plt.show()







##Diagrama de simbolos filtrados
#SIMBOLOS ENVIADOS
##Diagrama de simbolos filtrados

sI = np.zeros(len(symbolsI))
sQ = np.zeros(len(symbolsQ))
for ptr in range(len(symbolsI)):
    sI[ptr]=symbolsI[ptr]._getFloatValue()
for ptr in range(len(symbolsQ)):
    sQ[ptr]=symbolsQ[ptr]._getFloatValue()

plt.figure(figsize=[10,6])
plt.suptitle("Simbolos ENVIADOS")
plt.subplot(2,1,1)
plt.plot(sI,'o')
plt.xlim(0,200)
plt.grid(True)
plt.subplot(2,1,2)
plt.plot(sQ,'o')
plt.xlim(0,200)
plt.grid(True)

plt.show()


#extraigo datos para poder dibujarlos
sI_filtred = np.zeros(len(symbolsI_Filtred))
sQ_filtred = np.zeros(len(symbolsQ_Filtred))
for ptr in range(len(symbolsI_Filtred)):
    sI_filtred[ptr]=symbolsI_Filtred[ptr].fValue
for ptr in range(len(symbolsQ_Filtred)):
    sQ_filtred[ptr]=symbolsQ_Filtred[ptr].fValue


##Diagrama de simbolos filtrados
plt.figure(figsize=[10,6])
plt.suptitle("Simbolos RECIBIDOS")
plt.subplot(2,1,1)
plt.plot(sI_filtred,'o')
plt.xlim(0,200)
plt.grid(True)
plt.subplot(2,1,2)
plt.plot(sQ_filtred,'o')
plt.xlim(0,200)
plt.grid(True)

plt.show()

print(sI_filtred)
print(sI)
