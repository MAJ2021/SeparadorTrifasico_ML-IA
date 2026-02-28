model ControlSeparador
  import Modelica.Blocks.Continuous.PID;

  // Parámetros del separador
  parameter Real V = 20 "Volumen total del separador [m3]";
  parameter Real pSet = 1e6 "Presión de operación [Pa]";
  parameter Real T0 = 350 "Temperatura inicial [K]";

  // Estados (volúmenes parciales)
  Real Vgas(start=5);
  Real Voil(start=8);
  Real Vwater(start=7);
  Real p(start=pSet);
  Real T(start=T0);

  // Entradas de flujo
  input Real mInGas = 2 "Flujo másico de gas [kg/s]";
  input Real mInOil = 1.5 "Flujo másico de aceite [kg/s]";
  input Real mInWater = 1 "Flujo másico de agua [kg/s]";
  input Real Tin = 360 "Temperatura de entrada [K]";

  // Salidas de flujo
  output Real mOutGas;
  output Real mOutOil;
  output Real mOutWater;

  // Variables de nivel calculadas internamente
  Real levelOil;
  Real levelWater;

  // Controladores PID
  PID pidPressure(k=2, Ti=10, Td=0.1);
  PID pidOilLevel(k=1, Ti=20, Td=0.1);
  PID pidWaterLevel(k=1, Ti=20, Td=0.1);

equation
  // Balances de masa
  der(Vgas)   = (mInGas - mOutGas)/100;      // densidad gas aprox.
  der(Voil)   = (mInOil - mOutOil)/800;      // densidad aceite aprox.
  der(Vwater) = (mInWater - mOutWater)/1000; // densidad agua aprox.

  // Balance de energía simplificado
  der(T) = ( (mInGas*Tin + mInOil*Tin + mInWater*Tin)
            - (mOutGas*T + mOutOil*T + mOutWater*T) ) / (V*1000);

  // Presión proporcional al inventario de gas
  p = (Vgas/V) * pSet;

  // Cálculo de niveles relativos
  levelOil   = Voil / V;
  levelWater = Vwater / V;

  // Controladores PID conectados a las variables internas
  pidPressure.u = p;
  pidOilLevel.u = levelOil;
  pidWaterLevel.u = levelWater;

  // Salidas controladas por los PID
  mOutGas   = Vgas*0.05 + pidPressure.y;
  mOutOil   = Voil*0.05 + pidOilLevel.y;
  mOutWater = Vwater*0.05 + pidWaterLevel.y;


end ControlSeparador;
