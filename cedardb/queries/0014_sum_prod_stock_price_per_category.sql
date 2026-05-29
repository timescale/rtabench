SELECT
  sum(stock*price),
  category
FROM
    products
WHERE
    category = 'Electronics'
GROUP BY
    category;