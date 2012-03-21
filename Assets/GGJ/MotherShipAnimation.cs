using UnityEngine;
using System.Collections;

public class MotherShipAnimation : MonoBehaviour {
	public float yScale = 1.0f;
	public float rotationStep = 0.1f;
	private Vector3 initialPos;
	
	// Use this for initialization
	void Start () {
		initialPos = transform.position;
	}
	
	// Update is called once per frame
	void Update () {
		float y = yScale*Mathf.Cos(Time.timeSinceLevelLoad);
		transform.position = new Vector3(initialPos.x,initialPos.y+y,initialPos.z);
		
		transform.Rotate(new Vector3(0f,rotationStep,0f));
	}
}
