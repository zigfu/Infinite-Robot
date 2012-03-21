using UnityEngine;
using System.Collections;

public class EnemyVision : MonoBehaviour {

	// Use this for initialization
	void Start () {
	
	}


    public Transform hand1;
    public Transform hand2;
    public Transform head;
    public GameObject enableOnHandsToHead;
    public float handheadThreshold = .85f;
    public float hysteresis = .2f;
    bool visionOn = false;
    public GUIText txtOut;
	// Update is called once per frame
	void Update () {
        Vector3 hand1head = hand1.position - head.position;
        Vector3 hand2head = hand2.position - head.position;
        float amt = hand1head.magnitude + hand2head.magnitude; 
        txtOut.text = amt.ToString();
        if ((!visionOn) && (amt < handheadThreshold))
        {
            visionOn = true;
            enableOnHandsToHead.SetActiveRecursively(true);  
        }
        if ((visionOn) && (amt > (handheadThreshold+hysteresis)))
        {
            visionOn = false;
            enableOnHandsToHead.SetActiveRecursively(false);
        }
	}
}
