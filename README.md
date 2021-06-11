<!--
SPDX-FileCopyrightText: 2021 Felix Wolfsteller
SPDX-License-Identifier: AGPL-3.0-or-later
-->
# Migrate reward/Bonus points from Magento to shopware

Scripts to migrate bonus points from a magento 2.x shop (from mirasvit rewards
plugin) to a
shopware 5 shop (with some plugin?). Pretty specific use case.

## DB

Mirasvit stores the points in transactions, and the sums are not stored in db,
afaics.

Relevant db table is mst_rewards_transaction:

`"SELECT SUM(amount) FROM $table WHERE customer_id=?", [(int)$customer]`

`"SELECT customer_id, SUM(amount) as amount FROM $table GROUP BY customer_id"`


## Plan of action

  * Map customer ids to reward points

## Usage

## License

Code is copyright 2021 Felix Wolfsteller and released under the AGPLv3+ which is
included in the [`LICENSE`](LICENSE) file in full text. The project should be
[reuse](https://reuse.software) compliant.

However, these are only notes and scripts for a specific usecase. If you have a
(tiny) budget and need or some ideas about improvements, just get in contact.
