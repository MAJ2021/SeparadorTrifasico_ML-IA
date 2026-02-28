model SeparadorOil_V48_22
  // Parámetros del separador
  parameter Real V_sep   = 17.0;              // volumen del separador [m3]
  parameter Real Qin_base = 440/86400;        // caudal de entrada ~0.0051 m3/s
  parameter Real Qout_max = 0.0047;           // drenaje ajustado

  // Variables de estado
  Real V_oil(start=0.0);                      // volumen de oil [m3]
  Real Qin, Qout;                             // caudales
  Real valveOpening;                          // apertura de válvula
  Real V_oil_pct;                             // nivel en %
  Real spOil_pct;                             // setpoint en %
  Real error;                                 // error de control
  Real integralError(start=0);                // integral del error

  // Parámetros del PI
  parameter Real Kp = 0.0015;                 // ganancia proporcional
  parameter Real Ki = 2.0e-5;                 // ganancia integral

  // Tabla de referencia temporal para el setpoint
  Modelica.Blocks.Sources.CombiTimeTable refTable(
    table=[0,0; 1800,54; 3600,90],
    smoothness=Modelica.Blocks.Types.Smoothness.LinearSegments);

equation
  // Balance dinámico
  der(V_oil) = Qin - Qout;

  // Nivel en porcentaje
  V_oil_pct = (V_oil / V_sep) * 100;

  // Setpoint tomado de la tabla
  spOil_pct = refTable.y[1];

  // Error y control PI
  error = spOil_pct - V_oil_pct;
  der(integralError) = error;
  valveOpening = noEvent(min(max(Kp*error + Ki*integralError,0),1));

  // Caudal de salida dependiente del nivel
  Qout = valveOpening * Qout_max * (V_oil / V_sep);

  // Entrada fija
  Qin = Qin_base;
end SeparadorOil_V48_22;
