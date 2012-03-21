using UnityEngine;
using System.Collections;

public class MouseKeyboardControl : MonoBehaviour {
	private Vector3 startPos;
	
	private float currX;
	private float currY;
	
	void Start () {
		startPos = transform.localPosition;
		currX = 0.0f;
		currY = 0.0f;
	}
	
	// Update is called once per frame
	public float horizontalSpeed = 0.5f;
    public float verticalSpeed = 0.5f;
	public float minX = -0.5f;
	public float minY = -0.5f;
	public float maxX = 0.5f;
	public float maxY = 0.5f;
	
    void Update() {
        float h = horizontalSpeed * Input.GetAxis("Mouse X");
        float v = verticalSpeed * Input.GetAxis("Mouse Y");
		transform.Rotate(v,-h,0);	// z,x,y
		/*
		currX = Mathf.Clamp(currX+v,minX,maxX);
		currY = Mathf.Clamp(currY+h,minY,maxY);
		transform.localPosition = new Vector3(startPos.x+currX,startPos.y+currY,startPos.z);
		*/
    }
}
