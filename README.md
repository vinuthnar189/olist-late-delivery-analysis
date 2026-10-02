# olist-late-delivery-analysis
Why are some orders delivered late? A look at Olist delivery data

I wanted to find out where orders arrive later than promised, and why. I used a public dataset of about 99,000 online orders from Brazil (2016 to 2018) and worked with SQL and Excel.

What I did
Checked the data first. Before measuring anything, I tested the order dates against simple rules (for example, an order can't be delivered before the carrier picked it up). About 190 delivered orders broke a rule.
Checked whether that mattered. With those orders removed, the late rate moved from 8.11% to 8.13%. So the problems were too small to change the result, and I carried on with the cleaned data (96,281 orders).
Measured lateness. I counted an order as late if it arrived after its estimated delivery date. I looked at the late rate by state and by month.
Found where the time goes. I split each delivery into two parts: the days from purchase until the carrier picked it up, and the days from pickup until delivery.
Built the report in Excel with pivot tables, a lookup formula, a recorded macro that refreshes the report, and a one-page dashboard.
What I found
About 8.1% of delivered orders arrived late.
Rio de Janeiro stands out: 13.5% of its orders were late, compared with 5.9% in São Paulo. Rio has about 13% of all orders but about 21% of the late ones. Bahia is also high at 14.0%.
Three months caused a large share of the problem: November 2017, February 2018 and March 2018. Together they hold 22% of the orders but 46% of the late ones.
The delay happens in transit, not at the seller. In every state I checked, sellers handed orders to the carrier in about 3.2 to 3.3 days. Transit took 5.6 days in São Paulo, 12.0 in Rio and 16.0 in Bahia.
Slow delivery doesn't always mean late delivery. Amazonas has about 23.5 days in transit but only 4.1% of orders were late, while Rio is faster (12.0 days) but more often late. My guess is that the delivery dates promised to customers are too optimistic in some states and more generous in others. I haven't tested this.
What I would suggest

Look at carrier performance on the Rio and Bahia routes first, and check whether the delivery dates promised for the worst states are realistic. As a rough upper limit, if Rio were as reliable as the national average it would have about 660 fewer late orders, around 8% of all late orders. This is an estimate, not something I measured.

What I couldn't tell
The data has no distances, carrier names or seller locations, so I can't say why some routes are slower.
I didn't analyse individual sellers, because one order can contain items from several sellers.
The November 2017 peak may be seasonal (high order volume), but the data doesn't explain the March 2018 spike.
The data covers only 2016 to 2018.
Data and files
Dataset: Brazilian E-Commerce Public Dataset by Olist on Kaggle (licence CC BY-NC-SA 4.0). I used it for a non-commercial portfolio project. I haven't uploaded the raw data, so please download it from the link above.
olist_analysis.sql has every query I ran.
late_by_state.csv and late_by_month.csv are my summary results.
<img width="873" height="442" alt="image" src="https://github.com/user-attachments/assets/86182816-dd53-4e4a-a601-0c67b20fc52f" />
<img width="752" height="442" alt="image" src="https://github.com/user-attachments/assets/ae1beb5e-00d5-4fe2-88f6-f9e5a34114b2" />


Vinnutna Yerreddula
