##PRUEBA
import numpy as np
import matplotlib.pyplot as plt
##Libreria de funciones utiles 
from myfunc import rcosine, resp_freq, eyediagram


##-----------------------------Programa----------------------------------
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

#####------PRBS-RANDOM-SEQUENCE(version punto1)-------####
Nsymb= 1000
symbolsI = 2*(np.random.uniform(-1,1,Nsymb)>0.0)-1
symbolsQ = 2*(np.random.uniform(-1,1,Nsymb)>0.0)-1

##simbolos up-sampling
symbUpI = np.zeros(os*Nsymb)
symbUpI[1:len(symbUpI):int(os)]=symbolsI
symbUpQ = np.zeros(os*Nsymb)
symbUpQ[1:len(symbUpQ):int(os)]=symbolsQ


#FILTER 
symb00    = np.zeros(int(os)*3+1);symb00[os:len(symb00)-1:int(os)] = 1.0
(t,rc1) = rcosine(roll_off, T,os,Nbauds,Norm=False)
rc1Symb00 = np.convolve(rc1,symb00);




[H1,A1,F1] = resp_freq(rc1, Ts, Nfreqs)

symb_out_filterI = np.convolve(rc1,symbUpI,'same'); 
symb_out_filterQ = np.convolve(rc1,symbUpQ,'same')

#Receiver
offset= 1
symb_downI = symb_out_filterI[offset::os]
symb_downQ = symb_out_filterQ[offset::os]

umbral = 0.0
symb_detectedI = np.where(symb_downI >= umbral, 1, -1)
symb_detectedQ = np.where(symb_downQ >= umbral, 1, -1)


##BER
corrI = np.correlate(symb_downI,symbolsI)
corrQ = np.correlate(symb_downQ,symbolsQ)
print(corrI)
symbol_errI = ((Nsymb - corrI)//2)/2
symbol_errQ = ((Nsymb - corrQ)//2)/2

BER_I = (symbol_errI/symbolsI.size)*100
BER_Q = (symbol_errQ/symbolsQ.size)*100

print("BER_I= ", BER_I[0],"%")
print("BER_Q= ", BER_Q[0],"%")

### Generacion de las graficas respuesta al impulso
plt.figure(figsize=[14,7])
plt.suptitle("Respuesta al impulso y en frecuencia")
plt.subplot(2,2,1)
plt.plot(t,rc1,'gs-',linewidth=2.0,label=r'$\beta=0.5$')
plt.legend()
plt.grid(True)
plt.xlabel('Muestras')
plt.ylabel('Magnitud')



offsetPot = os*((Nbauds//2)-1) + int(os/2)*(Nbauds%2) + 0.5*(os%2 and Nbauds%2)
    
plt.subplot(2,2,(3,4))
plt.plot(np.arange(0,len(rc1)),rc1,'r.-',linewidth=2.0,label=r'$\beta=0.5$')
plt.plot(np.arange(os,len(rc1)+os),rc1,'k.-',linewidth=2.0,label=r'$\beta=0.5$')
plt.stem(np.arange(offsetPot,len(symb00)+offsetPot),symb00,label='Bits',use_line_collection=True)
plt.plot(rc1Symb00[os::],'--',linewidth=3.0,label='Convolution')
plt.legend()
plt.grid(True)
#plt.xlim(0,35)
plt.ylim(-0.2,1.4)
plt.xlabel('Muestras')
plt.ylabel('Magnitud')
plt.title('Rcosine - OS: %d'%int(os))
    
#plt.show()



##grafico de respuesta en frecuencia

plt.subplot(2,2,2)

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

##Simbolos
plt.figure(figsize=[10,6])
plt.suptitle("Simbolos")
plt.subplot(2,1,1)
plt.plot(symbUpI,'o')
plt.xlim(0,20)
plt.grid(True)
plt.subplot(2,1,2)
plt.plot(symbUpQ,'o')
plt.xlim(0,20)
plt.grid(True)

plt.show()

##Diagrama de simbolos filtrados
plt.figure(figsize=[10,6])
plt.suptitle("simbolos filtrados")
plt.subplot(2,1,1)
plt.plot(symb_out_filterI,'g-',linewidth=2.0,label=r'$\beta=%2.2f$'%roll_off)
plt.xlim(1000,1250)
plt.grid(True)
plt.legend()
plt.xlabel('Muestras')
plt.ylabel('Magnitud')
    
plt.subplot(2,1,2)
plt.plot(symb_out_filterQ,'g-',linewidth=2.0,label=r'$\beta=%2.2f$'%roll_off)
plt.xlim(1000,1250)
plt.grid(True)
plt.legend()
plt.xlabel('Muestras')
plt.ylabel('Magnitud')
plt.show()

##Diagrama de ojo
eyediagram(symb_out_filterI[100:len(symb_out_filterI)-100],os,5,Nbauds)
eyediagram(symb_out_filterQ[100:len(symb_out_filterQ)-100],os,5,Nbauds)
plt.show()


##Diagrama constelacion
plt.figure(figsize=[6,6])
plt.suptitle("Diagrama de constelacion")
for i in range(os):
    plt.subplot(2, os//2, i+1)
    plt.plot(symb_out_filterI[100+i:len(symb_out_filterI)-(100-i):int(os)],
            symb_out_filterQ[100+i:len(symb_out_filterQ)-(100-i):int(os)],
                '.',linewidth=2.0)
    plt.grid(True)
    plt.xlim((-2, 2))
    plt.ylim((-2, 2))
    plt.xlabel('Real')
    plt.ylabel('Imag')
    plt.legend(["offset:{}".format(i)])



    
plt.show()


