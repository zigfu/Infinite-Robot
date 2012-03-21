using UnityEngine;
using System.Collections;
using System.Linq;
using System;

public class PlayerBehaviorCS : MonoBehaviour {
	
	public Vector2 speed = new Vector2(5,8);
	public Vector2 bounds = new Vector2(5,3);
	public rotateToSelect XAxis;
	public rotateToSelect YAxis;
	

	// Use this for initialization
	void Start () {
		
	}
    void OnDestroy()
    {
 
    }

	// Update is called once per frame
    void Update()
    {

        Vector2 delta = Vector2.Scale(new Vector2(-XAxis.value, -YAxis.value), speed) * Time.deltaTime;
        
        //delta.x = -delta.x;
        
        transform.Translate(delta.x, delta.y, 0, Space.Self);
        transform.localPosition = new Vector2(Mathf.Clamp(transform.localPosition.x, -bounds.x, bounds.x),
                                          Mathf.Clamp(transform.localPosition.y, -bounds.y, bounds.y));

    }
		
}
