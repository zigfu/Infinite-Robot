using UnityEngine;
using System.Collections;

public class scoreKeeper : MonoBehaviour {

	public GUIText scoreText;
	public GUIText lifeText;
	int score = 0;
	public int hp = 100;
	
	public Renderer character;
	
	// Use this for initialization
	void Start () {
		scoreText.text = score.ToString();
		lifeText.text = hp.ToString() + "%";
	}
	
	public void AddScore(int amt)
	{
		score += amt;
		scoreText.text = score.ToString();
	}
	public void TakeDamage(int amt)
	{
		hp -= amt;
		
		if ((hp <= 0) && character.enabled)
		{
			hp = 0;
			character.enabled = false;
			StartCoroutine("Respawn");
			
			
		}
		lifeText.text = hp.ToString() + "%";	
	}
	IEnumerator Respawn()
	{
		yield return new WaitForSeconds(2);
		SetLife(100);
		
		character.enabled = true;
		AddScore(-500);
	}
	public void SetLife(int amt)
	{
		hp = amt;
		lifeText.text = hp.ToString() + "%";	
	}
	
	// Update is called once per frame
	void Update () {
	
	}
}
