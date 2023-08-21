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

Nsymb=2000
NB=10 ##8,7 queda media fea la resp en frec
NBF=9
round_mode='round'

##FILTRO COSENO REALZADO punto fijo
(t,coseno_realsado) = rcosine(roll_off, T,os,Nbauds,Norm=False)
coseno_r_FixPoint = arrayFixedInt(NB, NBF, coseno_realsado, signedMode='S', roundMode=round_mode, saturateMode='saturate')
#coseno_r_arr = np.zeros(len(coseno_r_FixPoint))
#for ptr in range(len(coseno_r_arr)):
#    coseno_r_arr[ptr]=coseno_r_FixPoint[ptr].fValue



#ind_i,ind_q=0
prbs9_i = np.array([1,1,0,1,0,1,0,1,0]) #SEEDS= I (9’h1AA) 
prbs9_q = np.array([1,1,1,1,1,1,1,1,0]) #SEEDS= Q (9’h1FE).
symbolsI= []
symbolsQ= []
##Asignacion de fase
firPhase = [[] for _ in range(os)]
for phase in range(os):
    firPhase[phase] = np.roll(coseno_r_FixPoint,-phase)

shiftFirI = np.zeros(os * Nbauds + 1)
shiftFirI = arrayFixedInt(NB, NBF, shiftFirI, signedMode='S', roundMode='round', saturateMode='saturate')
shiftFirQ = np.zeros(os * Nbauds + 1)
shiftFirQ = arrayFixedInt(NB, NBF, shiftFirQ, signedMode='S', roundMode='round', saturateMode='saturate')

firI=[]
firQ=[]
xval=0
hval=0

#print(shiftFir)

#->simula ciclo de reloj
for i in range(Nsymb):#len(prbs9_i)):
    ##PRBS9 para I
    prbs9_i = np.roll(prbs9_i,1)
    prbs9_q = np.roll(prbs9_q,1)
    prbs9_i[0] = prbs9_i[4] ^ prbs9_i[8]
    prbs9_q[0] = prbs9_q[4] ^ prbs9_q[8]

    bit_i_fixed = DeFixedInt(NB,NBF,'S',round_mode,'saturate')
    bit_q_fixed = DeFixedInt(NB,NBF,'S',round_mode,'saturate')
    ##Cambiamos el 1 por -1 y 0 por 1
    if(prbs9_i[8]==1):
        bit_i_fixed.value=-1.0 
        symbolsI.append(bit_i_fixed) 
    else:
        bit_i_fixed.value=1.0
        symbolsI.append(bit_i_fixed)
    
    if(prbs9_q[8]==1):
        bit_q_fixed.value=-1.0
        symbolsQ.append(bit_q_fixed)
    else:
        bit_q_fixed.value=1.0
        symbolsQ.append(bit_q_fixed)

    

    #shiftFirI sirve para hacer la convolucion con el filtro
    shiftFirI   = np.roll(shiftFirI,1)
    shiftFirQ   = np.roll(shiftFirQ,1)
    shiftFirI[0]= symbolsI[i]
    shiftFirQ[0]= symbolsQ[i]


    for phase in range(os):
        #---Version sin optimizacion
        #temp=firPhase[phase][0]*shiftFir[0]
        #for ind in range((os*Nbauds)-1):
        #    temp=(firPhase[phase][ind+1]*shiftFir[ind+1])+temp
        #firI.append(temp)

        #####SIMBOLS I#######
        if(shiftFirI[0].fValue > 0.0):
            tmp_I=firPhase[phase][0]    
        elif(shiftFirI[0].fValue < 0.0):
            tmp_I=firPhase[phase][0] * shiftFirI[0]#TODO: BUSCAR ALGO PARA HACER coeficiente negado
            if(i==0 and phase==0):
                print(firPhase[phase][0])
                print(shiftFirI[0])
                print(tmp_I)
        else:
            tmp_I=shiftFirI[0]

        for ind in range(int((os*Nbauds)/os)):
            if(shiftFirI[(ind+1)*os].fValue > 0.0):
                tmp_I= tmp_I + firPhase[phase][ind*os]  
            elif(shiftFirI[(ind+1)*os].fValue < 0.0):
                #negativo=DeFixedInt(NB,NBF,'S',round_mode,'saturate')
                tmp_I= tmp_I + (firPhase[phase][ind*os] * shiftFirI[(ind+1)*os]) 
            #else:
            #    tmp+=firPhase[phase][ind*os]
        if(i<16 and phase==0):
            print(firPhase[phase][0])
            print(shiftFirI[0])
            print(tmp_I.fValue)

        ###TODO:si es un valor > a 1 le agrego 1 si no 0
        ##salida del filtro con redondeo
        BIT_I       = DeFixedInt(NB,NBF,'S',round_mode,'saturate')#Si lo defino antes guarda basura
        if(tmp_I.fValue < 0.0):
            BIT_I.value=-1.0    
        elif(tmp_I.fValue > 0.0):
            BIT_I.value=1.0
        else:
            BIT_I.value=0.0
        firI.append(BIT_I)

        #####SIMBOLS Q#######------------------------------------------
        if(shiftFirQ[0].fValue > 0.0):
            tmp_Q=firPhase[phase][0]    
        elif(shiftFirQ[0].fValue < 0.0):
            tmp_Q=firPhase[phase][0] * shiftFirQ[0]#TODO: BUSCAR ALGO PARA HACER coeficiente negado
        else:
            tmp_Q=shiftFirQ[0]

        for ind in range(int((os*Nbauds)/os)):
            if(shiftFirQ[(ind+1)*os].fValue > 0.0):
                tmp_Q= tmp_Q + firPhase[phase][ind*os]  
            elif(shiftFirQ[(ind+1)*os].fValue < 0.0):
                tmp_Q= tmp_Q + (firPhase[phase][ind*os] * shiftFirQ[(ind+1)*os]) 
            #else:
            #    tmp+=firPhase[phase][ind*os]

        ###TODO:si es un valor > a 1 le agrego 1 si no 0
        ##salida del filtro con redondeo
        #BIT_Q       = DeFixedInt(NB,NBF,'S',round_mode,'saturate')#Si lo defino antes guarda basura
        #if(tmp_Q.fValue < 0.0):
        #    BIT_Q.value=-1.0    
        #elif(tmp_Q.fValue > 0.0):
        #    BIT_Q.value=1.0
        #else:
        #    BIT_Q.value=0.0
        firQ.append(tmp_Q)


simb_total_I = np.zeros(len(firI))
simb_total_Q = np.zeros(len(firQ))
for i in range(len(firI)):
    simb_total_I[i]=firI[i].fValue
for i in range(len(firQ)):
    simb_total_Q[i]=firQ[i].fValue

offset=64#os*16 retraso de mi filtro

sib_reciv_i= firI[offset::os]; simb_recibI= np.zeros(len(sib_reciv_i))
sib_reciv_q= firQ[offset::os]; simb_recibQ= np.zeros(len(sib_reciv_q))

for i in range(len(sib_reciv_i)):
    simb_recibI[i]=sib_reciv_i[i].fValue
for i in range(len(sib_reciv_q)):
    simb_recibQ[i]=sib_reciv_q[i].fValue
    





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
#plt.show()


#SIMBOLOS ENVIADOS
##Diagrama de simbolos filtrados
sI = np.zeros(len(symbolsI))
for ptr in range(len(symbolsI)):
    sI[ptr]=symbolsI[ptr]._getFloatValue()
sQ = np.zeros(len(symbolsQ))
for ptr in range(len(symbolsQ)):
    sQ[ptr]=symbolsQ[ptr]._getFloatValue()

plt.figure(figsize=[10,6])
plt.suptitle("Simbolos ENVIADOS")
plt.subplot(2,1,1)
plt.plot(sI,'o')
plt.xlim(0,100)
plt.grid(True)
plt.subplot(2,1,2)
plt.plot(sQ,'o')
plt.xlim(0,100)
plt.grid(True)

#plt.show()

##Diagrama de simbolos filtrados
plt.figure(figsize=[10,6])
plt.suptitle("Simbolos RECIBIDOS")
plt.subplot(2,1,1)
plt.plot(simb_recibI,'o')
plt.xlim(0,100)
plt.ylim(-2,2)
plt.grid(True)
plt.subplot(2,1,2)
plt.plot(simb_recibQ,'o')
plt.xlim(0,100)
plt.grid(True)

##Diagrama de ojo
eyediagram(simb_recibI[64:len(simb_recibI)-64],os,5,Nbauds)
eyediagram(simb_recibQ[100:len(simb_recibQ)-100],os,5,Nbauds)



##Diagrama constelacion
plt.figure(figsize=[6,6])
plt.suptitle("Diagrama de constelacion")
for i in range(os):
    plt.subplot(2, os//2, i+1)
    plt.plot(simb_total_I[100+i:len(simb_total_I)-(100-i):int(os)],
            simb_total_Q[100+i:len(simb_total_Q)-(100-i):int(os)],
                '.',linewidth=2.0)
    plt.grid(True)
    plt.xlim((-2, 2))
    plt.ylim((-2, 2))
    plt.xlabel('Real')
    plt.ylabel('Imag')
    plt.legend(["offset:{}".format(i)])


plt.show()
