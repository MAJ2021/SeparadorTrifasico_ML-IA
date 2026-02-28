model DosSeparadorsParaleloDesarroloV50_2_2
  // Parámetros básicos
  parameter Real V_sep = 17;          // volumen separador [m3]
  parameter Real Q_agua_in = 83;      // caudal agua [m3/h]
  parameter Real Q_petroleo_in = 20;  // caudal petróleo [m3/h]

  // Setpoints de referencia
  parameter Real SP_general  = 75;
  parameter Real SP_petroleo = 54;

  // Estados dinámicos
  Real nivelAgua(start=0);
  Real nivelPetroleo(start=0);

  // Variables de salida para graficar
  Real nivelGeneral;
  Real nivelAgua_pct;
  Real nivelPetroleo_pct;
  Real nivelGeneral_pct;

  // Caudales de salida (definidos por funciones simples)
  Real Q_out_agua;
  Real Q_out_petroleo;

equation
  // Balance dinámico agua
  der(nivelAgua) = (Q_agua_in/2 - Q_out_agua)/3600;

  // Balance dinámico petróleo
  der(nivelPetroleo) = (Q_petroleo_in/2 - Q_out_petroleo)/3600;

  // Cálculo de niveles
  nivelGeneral      = nivelAgua + nivelPetroleo;
  nivelAgua_pct     = (nivelAgua/V_sep)*100;
  nivelPetroleo_pct = (nivelPetroleo/V_sep)*100;
  nivelGeneral_pct  = (nivelGeneral/V_sep)*100;

  // Descargas simples (lineales con saturación)
  Q_out_agua     = max(0, (nivelAgua_pct/SP_general)) * (nivelAgua/10);
  Q_out_petroleo = max(0, (nivelPetroleo_pct/SP_petroleo)) * (nivelPetroleo/10);

end DosSeparadorsParaleloDesarroloV50_2_2;
