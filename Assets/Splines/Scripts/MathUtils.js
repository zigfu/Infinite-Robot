class MathUtils
{
	//
	//
	//
	static function GetQuatLength(q : Quaternion) : float
	{
		return Mathf.Sqrt(q.x*q.x + q.y*q.y + q.z*q.z + q.w*q.w);	
	}
	
	//
	//
	//
	static function GetQuatConjugate(q : Quaternion) : Quaternion
	{
		return Quaternion(-q.x, -q.y, -q.z, q.w);
	}
	
	//	// Logarithm of a unit quaternion. The result is not necessary a unit quaternion.	// 
	static function GetQuatLog(q : Quaternion) : Quaternion
	{
		var res : Quaternion = q;		res.w = 0;
	
		if (Mathf.Abs(q.w) < 1.0)
		{					var theta : float = Mathf.Acos(q.w);			var sin_theta : float = Mathf.Sin(theta);			if (Mathf.Abs(sin_theta) > 0.0001)
			{
				var coef:float = theta/sin_theta;      			res.x = q.x*coef;
      			res.y = q.y*coef;
      			res.z = q.z*coef;
   			}		}   		return res;
	}

	//
	// Exp
	//
	static function GetQuatExp(q : Quaternion) : Quaternion
	{
		var res : Quaternion = q;
		
    	var fAngle:float = Mathf.Sqrt(q.x*q.x + q.y*q.y + q.z*q.z);    
		var fSin:float = Mathf.Sin(fAngle);
		
    	res.w = Mathf.Cos(fAngle);

    	if (Mathf.Abs(fSin) > 0.0001)
    	{
        	var coef:float = fSin/fAngle;
        	res.x = coef*q.x;
        	res.y = coef*q.y;
        	res.z = coef*q.z;
    	}
    	
		return res;
	} 

	//
	// SQUAD Spherical Quadrangle interpolation [Shoe87]
	//
	static function GetQuatSquad (t : float, q0 : Quaternion, q1 : Quaternion, a0 : Quaternion, a1 : Quaternion)
	{
		var slerpT:float = 2.0*t*(1.0-t);
    
    	var slerpP = Slerp(q0, q1, t);
    	var slerpQ = Slerp(a0, a1, t);
    
    	return Slerp(slerpP, slerpQ, slerpT); 
	}

	static function GetSquadIntermediate (q0:Quaternion, q1:Quaternion, q2:Quaternion)
	{
    	var q1Inv : Quaternion = GetQuatConjugate(q1);
    	var p0 = GetQuatLog(q1Inv*q0);
    	var p2 = GetQuatLog(q1Inv*q2);
    	var sum : Quaternion = Quaternion(-0.25*(p0.x+p2.x), -0.25*(p0.y+p2.y), -0.25*(p0.z+p2.z), -0.25*(p0.w+p2.w));
   	
    	return q1*GetQuatExp(sum);
	}
	
	//
	// Smooths the input parameter t. If less than k1 ir greater than k2, it uses a sin. Between k1 and k2 it uses 
	// linear interp.
	//
	static function Ease(t : float, k1 : float, k2 : float) : float
	{ 
  		var f:float; var s:float; 
  
  		f = k1*2/Mathf.PI + k2 - k1 + (1.0-k2)*2/Mathf.PI;
  
  		if (t < k1) 
  		{ 
    		s = k1*(2/Mathf.PI)*(Mathf.Sin((t/k1)*Mathf.PI/2-Mathf.PI/2)+1); 
  		} 
  		else 
  		if (t < k2) 
  		{ 
    		s = (2*k1/Mathf.PI + t-k1); 
  		} 
  		else 
  		{ 
    		s= 2*k1/Mathf.PI + k2-k1 + ((1-k2)*(2/Mathf.PI))*Mathf.Sin(((t-k2)/(1.0-k2))*Mathf.PI/2); 
  		} 
  
  		return (s/f); 
	}
	
	//
	// We need this because Quaternion.Slerp always does it using the shortest arc
	//
	static function Slerp (p : Quaternion, q : Quaternion, t : float) : Quaternion
	{
		var ret : Quaternion;
		
    	var fCos : float = Quaternion.Dot(p, q);
    	
    	if ((1.0 + fCos) > 0.00001)
    	{
    		if ((1.0 - fCos) > 0.00001)
    		{
    			var omega : float = Mathf.Acos(fCos);
    			var invSin : float = 1.0/Mathf.Sin(omega);
    			var fCoeff0  : float = Mathf.Sin((1.0-t)*omega)*invSin;
    			var fCoeff1  : float = Mathf.Sin(t*omega)*invSin;
    		}
    		else
    		{
    			fCoeff0 = 1.0-t;
    			fCoeff1 = t;
    		}
    		
    		ret.x = fCoeff0*p.x + fCoeff1*q.x;
   		    ret.y = fCoeff0*p.y + fCoeff1*q.y;
   		    ret.z = fCoeff0*p.z + fCoeff1*q.z;
   		    ret.w = fCoeff0*p.w + fCoeff1*q.w;    		
    	}
    	else
    	{
    		fCoeff0 = Mathf.Sin((1.0-t)*Mathf.PI*0.5);
    		fCoeff1 = Mathf.Sin(t*Mathf.PI*0.5);
    		
    		ret.x = fCoeff0*p.x - fCoeff1*p.y;
   		    ret.y = fCoeff0*p.y + fCoeff1*p.x;
   		    ret.z = fCoeff0*p.z - fCoeff1*p.w;
       		ret.w =  p.z;
    	}
    	    
    	return ret;
	}
	
}