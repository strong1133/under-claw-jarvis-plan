# ADR (Architecture Decision Records)

되돌리기 어려운 결정과 **그때의 근거**를 남긴다. 지금의 코드는 "무엇"만 말해주고 "왜"는 말해주지 않는다.

## 언제 쓰나

- 되돌리려면 여러 파일·모듈을 고쳐야 하는 결정
- 합리적인 대안이 둘 이상 있었던 결정
- 나중에 "왜 이렇게 했지?" 소리가 나올 결정
- 지침·문서 구조 자체를 바꾼 결정

일상적인 구현 선택은 대상이 아니다. 그건 코드 리뷰에서 끝난다.

## 규칙

- 파일명: `NNNN-kebab-case-제목.md` (`0001` 부터 순번, 재사용 금지)
- 새 문서는 [`TEMPLATE.md`](TEMPLATE.md) 복사로 시작
- **기존 ADR 은 수정하지 않는다.** 결정이 바뀌면 새 ADR 을 쓰고, 옛 문서 상태를 `superseded by NNNN` 으로만 바꾼다
- 상태: `proposed` / `accepted` / `superseded by NNNN` / `deprecated`

## 목록

| 번호 | 제목 | 상태 |
|---|---|---|
| [0001](0001-instruction-hierarchy.md) | 지침 문서를 계층화한다 | accepted |
