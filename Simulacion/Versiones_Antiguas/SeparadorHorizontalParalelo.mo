model SistemaSeparadoresEscalado
  import Modelica.Blocks.Continuous.LimPID;

  // Parámetros en m3 y m3/día
  parameter Real V_sep = 17;
  parameter Real q_water_total = 2000; // m3/día
  parameter Real q_oil_total = 440;    // m3/día
  
  parameter Real sp_nivel_gral = 0.75; // 75%
  parameter Real sp_oil_frac = 0.54;   // 54%

  model SeparadorFirme
    parameter Real V_max = 17;
    // Estados iniciales en m3 (números grandes para estabilidad)
    Real V_w(start=6, min=0.001);
    Real V_o(start=6, min=0.001);
    
    Real nivel_total;
    Real fraccion_oil;
    Real q_in_w, q_in_o, q_out_w, q_out_o;
  equation
    nivel_total = (V_w + V_o) / V_max;
    fraccion_oil = V_o / max(0.1, V_w + V_o);
    
    // Balance en m3/día (el tiempo de simulación será en "días")
    der(V_w) = q_in_w - q_out_w;
    der(V_o) = q_in_o - q_out_o;
  end SeparadorFirme;

  SeparadorFirme sepA(V_max=V_sep);
  SeparadorFirme sepB(V_max=V_sep);

  // PIDs con k más alta porque ahora los errores son en m3
  LimPID pidAgua(u_s=sp_nivel_gral, k=5, Ti=0.1, yMax=1, yMin=0);
  LimPID pidOil(u_s=sp_oil_frac, k=5, Ti=0.1, yMax=1, yMin=0);

equation
  // Entradas (Reparto 50/50 entre los dos separadores)
  sepA.q_in_w = q_water_total / 2;
  sepB.q_in_w = q_water_total / 2;
  sepA.q_in_o = q_oil_total / 2;
  sepB.q_in_o = q_oil_total / 2;

  // Control Sep A
  pidAgua.u_m = sepA.nivel_total;
  sepA.q_out_w = pidAgua.y * (q_water_total); // Válvula con capacidad de sobra

  pidOil.u_m = sepA.fraccion_oil;
  sepA.q_out_o = pidOil.y * (q_oil_total);

  // El Sep B copia el comportamiento del A (Paralelo simétrico)
  sepB.q_out_w = sepA.q_out_w;
  sepB.q_out_o = sepA.q_out_o;

end SistemaSeparadoresEscalado;

